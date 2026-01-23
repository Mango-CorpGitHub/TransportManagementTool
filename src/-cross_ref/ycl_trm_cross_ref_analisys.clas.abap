CLASS ycl_trm_cross_ref_analisys DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES ty_t_objects      TYPE STANDARD TABLE OF cnvcdmccts_objects_set WITH DEFAULT KEY.
    TYPES ty_t_objs_ref_tab TYPE STANDARD TABLE OF cnvcdmccts_objs_ref WITH DEFAULT KEY.

    TYPES: BEGIN OF ty_s_pre_object_analisys,
             analyzed_objects     TYPE ty_t_objects,
             not_analyzed_objects TYPE ty_t_objects,
           END OF ty_s_pre_object_analisys.

    TYPES ty_t_result TYPE STANDARD TABLE OF yif_trm_cross_reference=>ty_s_result WITH NON-UNIQUE KEY reference_fragid reference_fragment reference_fragname.

    TYPES: BEGIN OF ty_s_return,
             analized_objets_resume TYPE ty_s_pre_object_analisys,
             result                 TYPE yif_trm_cross_reference=>tab,
           END OF ty_s_return.

    METHODS run
      IMPORTING it_objects         TYPE ty_t_objects
      RETURNING VALUE(rs_analysis) TYPE ty_s_return
      RAISING   ycx_trm_cross_reference.

    METHODS constructor
      IMPORTING iv_rfc_comparison TYPE rfcdes-rfcdest.

  PRIVATE SECTION.
    DATA ai_t_namespace       TYPE STANDARD TABLE OF /sdf/cmo_namespace_long WITH DEFAULT KEY.
    DATA ai_rfc_destination   TYPE rfcdes-rfcdest.
    DATA ai_t_order_fragments TYPE ycl_trm_cross_ref_analisys=>ty_t_objects.

    METHODS prepare_importing_objects
      IMPORTING it_objects        TYPE ty_t_objects
      RETURNING VALUE(rs_objects) TYPE ty_s_pre_object_analisys.

    METHODS is_sap_object
      IMPORTING is_object               TYPE cnvcdmccts_objects_set
      RETURNING VALUE(rv_is_sap_object) TYPE abap_bool.

    METHODS methods_exists
      IMPORTING is_object               TYPE cnvcdmccts_objects_set
      RETURNING VALUE(rv_method_exists) TYPE abap_bool.

    METHODS get_cross_reference
      IMPORTING it_objects                TYPE ty_t_objects
      RETURNING VALUE(rt_cross_reference) TYPE ty_t_objs_ref_tab
      RAISING   ycx_trm_cross_reference.

    METHODS build_reference_list
      IMPORTING it_cross_reference       TYPE ty_t_objs_ref_tab
      RETURNING VALUE(rt_reference_list) TYPE ty_t_result.

    METHODS check_if_in_transport_request
      IMPORTING it_result                TYPE ycl_trm_cross_ref_analisys=>ty_t_result
                it_importing_objects     TYPE ycl_trm_cross_ref_analisys=>ty_t_objects
      RETURNING VALUE(rt_reference_list) TYPE ycl_trm_cross_ref_analisys=>ty_t_result.

    METHODS check_against_rfc
      IMPORTING it_result                TYPE ycl_trm_cross_ref_analisys=>ty_t_result
      RETURNING VALUE(rt_reference_list) TYPE ycl_trm_cross_ref_analisys=>ty_t_result.

    METHODS check_not_sap_object
      IMPORTING it_result                TYPE ycl_trm_cross_ref_analisys=>ty_t_result
      RETURNING VALUE(rt_reference_list) TYPE ycl_trm_cross_ref_analisys=>ty_t_result.

    METHODS get_with_fragments
      IMPORTING it_objects       TYPE ycl_trm_cross_ref_analisys=>ty_t_objects
      RETURNING VALUE(rt_result) TYPE ycl_trm_cross_ref_analisys=>ty_t_objects.

    METHODS check_methods
      IMPORTING it_result                TYPE ycl_trm_cross_ref_analisys=>ty_t_result
      RETURNING VALUE(rt_reference_list) TYPE ycl_trm_cross_ref_analisys=>ty_t_result.

    METHODS check_interfaces
      IMPORTING it_result          TYPE ycl_trm_cross_ref_analisys=>ty_t_result
                it_cross_reference TYPE ty_t_objs_ref_tab
      RETURNING VALUE(rt_result)   TYPE ycl_trm_cross_ref_analisys=>ty_t_result.

    METHODS check_cpub_cpro_cpri
      IMPORTING it_result          TYPE ycl_trm_cross_ref_analisys=>ty_t_result
                it_cross_reference TYPE ty_t_objs_ref_tab
      RETURNING VALUE(rt_result)   TYPE ycl_trm_cross_ref_analisys=>ty_t_result.

    METHODS check_devc
      IMPORTING it_result        TYPE ycl_trm_cross_ref_analisys=>ty_t_result
      RETURNING VALUE(rt_result) TYPE ycl_trm_cross_ref_analisys=>ty_t_result.

ENDCLASS.


CLASS ycl_trm_cross_ref_analisys IMPLEMENTATION.
  METHOD constructor.
    ai_rfc_destination = iv_rfc_comparison.
    CALL FUNCTION '/SDF/CMO_NAMESPACE_INFO'
      TABLES et_namespace = ai_t_namespace.

    ycl_trm_cross_ref_describe_obj=>free_cache( ).
  ENDMETHOD.

  METHOD run.
*------------------------------------------------
* Get dependencies
*------------------------------------------------

    ai_t_order_fragments = get_with_fragments( it_objects ).

    FINAL(ls_request_objets_resume) = prepare_importing_objects( ai_t_order_fragments ).

    FINAL(lt_cross_reference) = get_cross_reference( ls_request_objets_resume-analyzed_objects ).
    IF lt_cross_reference IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lt_result) = build_reference_list( lt_cross_reference ).
    IF lt_result IS INITIAL.
      RETURN.
    ENDIF.

*------------------------------------------------
* Analyse dependencies
*------------------------------------------------

    lt_result = check_not_sap_object( lt_result ).

    lt_result = check_if_in_transport_request( it_result            = lt_result
                                               it_importing_objects = ai_t_order_fragments ).

    lt_result = check_methods( lt_result ).

    lt_result = check_devc( lt_result ).

    lt_result = check_against_rfc( lt_result ).

*------------------------------------------------
* Indagar en las dependencias que se tienen que validar por el usuario
*------------------------------------------------

    lt_result = check_interfaces( it_result          = lt_result
                                  it_cross_reference = lt_cross_reference ).

    lt_result = check_cpub_cpro_cpri( it_result          = lt_result
                                      it_cross_reference = lt_cross_reference ).

*------------------------------------------------
* Return result
*------------------------------------------------

    RETURN VALUE ty_s_return( analized_objets_resume = ls_request_objets_resume
                              result                 = VALUE #( FOR ls_result IN lt_result
                                                                ( ycl_trm_cross_ref=>create( ls_result ) ) ) ).
  ENDMETHOD.

  METHOD get_cross_reference.
    DATA lt_messages  TYPE TABLE OF cnvcdmc_messages.
*---------------------------------------------------------------------
* Add additional reference for CPUB, CPRI, CPRO ( con los métodos )
*---------------------------------------------------------------------
    DATA lt_seomethod TYPE STANDARD TABLE OF vseomethod WITH DEFAULT KEY.
    DATA lt_seoredef  TYPE STANDARD TABLE OF seoredef WITH DEFAULT KEY.

    DATA(lt_objects) = it_objects.
    IF lt_objects IS INITIAL.
      FINAL(lo_log) = ycl_trm_logger=>new( ).
      MESSAGE s019(ytrm) INTO FINAL(lv_message) ##NEEDED.
      lo_log->add_message( CORRESPONDING #( sy ) ).
      RAISE EXCEPTION NEW ycx_trm_cross_reference( logger = lo_log ).
      RETURN.
    ENDIF.

    CALL FUNCTION '/SDF/TEAP_GET_REF_OBJECTS'
      TABLES     it_objs                    = lt_objects
                 it_obj_ref_tab             = rt_cross_reference
                 et_messages                = lt_messages
      EXCEPTIONS no_objs_specified_for_anal = 1
                 no_ref_found               = 2
                 OTHERS                     = 3.

    DELETE rt_cross_reference WHERE     ref_pgmid    IS INITIAL
                                    AND ref_obj_type IS INITIAL
                                    AND ref_obj_name IS INITIAL.

    DELETE rt_cross_reference WHERE     ref_pgmid    = 'R3TR'
                                    AND ref_obj_type = 'PROG'.

    DELETE rt_cross_reference WHERE     ref_pgmid    = 'LIMU'
                                    AND ref_obj_type = 'REPS'.

*---------------------------------------------------------------------
* Add additional reference from METH -> CP*
*---------------------------------------------------------------------
    DATA(lt_methods) = lt_objects[].
    DELETE lt_methods WHERE obj_type <> 'METH'.

    SORT lt_methods BY obj_name ASCENDING.
    DELETE ADJACENT DUPLICATES FROM lt_methods.

    " TODO: variable is assigned but only used in commented-out code (ABAP cleaner)
    FINAL(lt_meth) = lt_methods.
    " TODO: variable is assigned but only used in commented-out code (ABAP cleaner)
    FINAL(lt_et_meth) = lt_methods.
*    CALL FUNCTION '/SDF/TEAP_RESOLVE_METH'
*      TABLES it_objs = lt_meth
*             et_objs = lt_et_meth
*             tt_meth = lt_methods.

    LOOP AT lt_methods ASSIGNING FIELD-SYMBOL(<ls_method>).

      CASE <ls_method>-pgmid.

        WHEN 'CPRI' OR 'CPUB' OR 'CPRO'.

          INSERT VALUE cnvcdmccts_objs_ref( pgmid        = 'LIMU'
                                            obj_type     = 'METH'
                                            obj_name     = <ls_method>-obj_name
                                            ref_pgmid    = 'LIMU'
                                            ref_obj_type = <ls_method>-pgmid
                                            ref_obj_name = <ls_method>-obj_name(30) )
                 INTO TABLE rt_cross_reference.

        WHEN OTHERS. " Defined in interface

          SPLIT <ls_method>-obj_name+30(90) AT '~'
                " TODO: variable is assigned but never used (ABAP cleaner)
                INTO FINAL(lv_intf_name) FINAL(lv_meth_obj_name).

          INSERT VALUE cnvcdmccts_objs_ref( pgmid        = 'LIMU'
                                            obj_type     = 'METH'
                                            obj_name     = <ls_method>-obj_name
                                            ref_pgmid    = 'R3TR'
                                            ref_obj_type = 'INTF'
                                            ref_obj_name = lv_intf_name )
                 INTO TABLE rt_cross_reference.

      ENDCASE.

    ENDLOOP.

*---------------------------------------------------------------------
* Add additional reference for CPUB, CPRI, CPRO
*---------------------------------------------------------------------

    DATA(lt_class_parts) = lt_objects[].
    DELETE lt_class_parts WHERE obj_type <> 'CPUB' AND obj_type <> 'CPRO' AND obj_type <> 'CPRI'.

    LOOP AT lt_class_parts ASSIGNING FIELD-SYMBOL(<ls_class_part>).

      CONCATENATE 'SVRS_GET_VERSION_' <ls_class_part>-obj_type '_40'
                  INTO FINAL(lv_func_name).

      CLEAR: lt_seomethod,
             lt_seoredef.

      CALL FUNCTION lv_func_name
        EXPORTING  object_name           = CONV vrsd-objname( <ls_class_part>-obj_name )
                   versno                = CONV vrsd-versno( '00000' )
        TABLES     pvseomethod           = lt_seomethod
                   pseoredef             = lt_seoredef
        EXCEPTIONS no_version            = 1
                   system_failure        = 2
                   communication_failure = 3
                   OTHERS                = 4.

      LOOP AT lt_seomethod ASSIGNING FIELD-SYMBOL(<ls_seomethod>).

        INSERT VALUE cnvcdmccts_objs_ref( pgmid        = <ls_class_part>-pgmid
                                          obj_type     = <ls_class_part>-obj_type
                                          obj_name     = <ls_class_part>-obj_name
                                          ref_pgmid    = 'LIMU'
                                          ref_obj_type = 'METH'
                                          ref_obj_name = |{ <ls_class_part>-obj_name }~{ <ls_seomethod>-cmpname }| )
               INTO TABLE rt_cross_reference.

      ENDLOOP.

      LOOP AT lt_seoredef ASSIGNING FIELD-SYMBOL(<ls_seoredef>).

        INSERT VALUE cnvcdmccts_objs_ref( pgmid        = <ls_class_part>-pgmid
                                          obj_type     = <ls_class_part>-obj_type
                                          obj_name     = <ls_class_part>-obj_name
                                          ref_pgmid    = 'LIMU'
                                          ref_obj_type = 'METH'
                                          ref_obj_name = |{ <ls_class_part>-obj_name }~{ <ls_seoredef>-mtdname }| )
               INTO TABLE rt_cross_reference.

      ENDLOOP.

    ENDLOOP.
  ENDMETHOD.

  METHOD prepare_importing_objects.
    " Obtener los fragments...
    DATA(lt_objects) = it_objects.

    " Change CINC for REPS...
    LOOP AT lt_objects ASSIGNING FIELD-SYMBOL(<ls_object>).
      IF <ls_object>-obj_type = 'CINC'.
        <ls_object>-obj_type = 'REPS'.
      ENDIF.
    ENDLOOP.

    " Only cross-check on supported types:
    CONCATENATE 'DOMA DOMD DTEL DTED SHLP SHLD ENQU ENQD VIEW VIED'
                'TABL TABD TTYP TTYD TYPE TYPD PROG REPS FUNC METH CLAS INTF'
                'CPUB CPRI CPRO CLSD DYNP FUGR DDLS TRAN ENHO VKOS CFDF' INTO FINAL(lv_supported_types_string)
                SEPARATED BY space.

    SPLIT lv_supported_types_string AT space INTO TABLE FINAL(lt_suported_types).
    LOOP AT lt_objects INTO FINAL(ls_objects).

      IF NOT line_exists( lt_suported_types[ table_line = ls_objects-obj_type ] ).
        INSERT ls_objects INTO TABLE rs_objects-not_analyzed_objects.
        CONTINUE.
      ENDIF.

      IF is_sap_object( ls_objects ).
        INSERT ls_objects INTO TABLE rs_objects-not_analyzed_objects.
        CONTINUE.
      ENDIF.

      IF NOT methods_exists( ls_objects ).
        INSERT ls_objects INTO TABLE rs_objects-not_analyzed_objects.
        CONTINUE.
      ENDIF.

      INSERT ls_objects INTO TABLE rs_objects-analyzed_objects.

    ENDLOOP.

    " Delete duplicates...
    SORT rs_objects-analyzed_objects BY pgmid
                                        obj_type
                                        obj_name.
    DELETE ADJACENT DUPLICATES FROM rs_objects-analyzed_objects.

    SORT rs_objects-not_analyzed_objects BY pgmid
                                            obj_type
                                            obj_name.
    DELETE ADJACENT DUPLICATES FROM rs_objects-not_analyzed_objects.
  ENDMETHOD.

  METHOD is_sap_object.
    DATA ls_e071      TYPE e071.
    DATA lv_namespace TYPE trnspace-namespace.
    DATA ls_namespace TYPE /sdf/cmo_namespace_long.

    ls_e071-pgmid    = is_object-pgmid.
    ls_e071-object   = is_object-obj_type.
    ls_e071-obj_name = is_object-obj_name.

    IF ls_e071-object = 'FUNC'.
      CALL FUNCTION '/SDF/TEAP_TR_CHECK_TYPE'
        EXPORTING wi_e071      = ls_e071
        IMPORTING ev_namespace = lv_namespace.
    ELSE.
      CALL FUNCTION 'TR_CHECK_TYPE'
        EXPORTING wi_e071      = ls_e071
        IMPORTING ev_namespace = lv_namespace.
    ENDIF.

* Check if the name space is SAP or CUST
    IF lv_namespace <> '/0SAP/' AND lv_namespace <> '/0CUST/'.
      READ TABLE ai_t_namespace INTO ls_namespace WITH KEY namespace = lv_namespace.
      IF sy-subrc = 0.
        IF ls_namespace-ns_info = 'SAP'.
          lv_namespace = '/0SAP/'.
        ELSE.
          lv_namespace = '/0CUST/'.
        ENDIF.
      ELSE.
        lv_namespace = '/0CUST/'.
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD methods_exists.
    DATA lv_cls_name2  TYPE tmdir-classname.
    DATA lv_meth2      TYPE eu_lname.
    DATA lv_meth_name2 TYPE tmdir-methodname.

    IF is_object-obj_type <> 'METH'.
      RETURN abap_true.
    ENDIF.

    lv_cls_name2 = is_object-obj_name+0(30).
    CONDENSE lv_cls_name2 NO-GAPS.

    lv_meth2 = is_object-obj_name.
    REPLACE lv_meth2
            LENGTH 30
            WITH space
            INTO   lv_meth2.

    CONDENSE lv_meth2 NO-GAPS.
    lv_meth_name2 = lv_meth2.

    CALL FUNCTION 'RPY_EXISTENCE_CHECK_METH'
      EXPORTING  class     = lv_cls_name2
                 method    = lv_meth_name2
      EXCEPTIONS not_exist = 1.

    RETURN xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD build_reference_list.
    " Add Objects:

    DATA lt_range_to_delete TYPE RANGE OF yif_trm_cross_reference=>ty_s_result-reference_fragname.

    LOOP AT it_cross_reference ASSIGNING FIELD-SYMBOL(<ls_cross_reference>).

      CALL FUNCTION 'TR_GET_PGMID_FOR_OBJECT'
        EXPORTING  iv_object      = <ls_cross_reference>-ref_obj_type
        EXCEPTIONS illegal_object = 1
                   OTHERS         = 2.
      IF sy-subrc <> 0.
        CONTINUE. " Is subobject...
      ENDIF.

      ASSIGN rt_reference_list[ reference_fragid   = <ls_cross_reference>-ref_pgmid
                                reference_fragment = <ls_cross_reference>-ref_obj_type
                                reference_fragname = <ls_cross_reference>-ref_obj_name ] TO FIELD-SYMBOL(<ls_reference_list>) ELSE UNASSIGN.
      IF <ls_reference_list> IS ASSIGNED.

        <ls_reference_list>-object_list = VALUE #( BASE <ls_reference_list>-object_list
                                                   ( pgmid = <ls_cross_reference>-pgmid
                                                     type  = <ls_cross_reference>-obj_type
                                                     name  = <ls_cross_reference>-obj_name ) ).

        CONTINUE.
      ENDIF.

      INSERT VALUE yif_trm_cross_reference=>ty_s_result(
                       reference_fragid   = <ls_cross_reference>-ref_pgmid
                       reference_fragment = <ls_cross_reference>-ref_obj_type
                       reference_fragname = <ls_cross_reference>-ref_obj_name
                       object_list        = VALUE #( ( pgmid = <ls_cross_reference>-pgmid
                                                       type  = <ls_cross_reference>-obj_type
                                                       name  = <ls_cross_reference>-obj_name ) ) ) INTO TABLE rt_reference_list.

    ENDLOOP.

    " Change notation...
    DATA lt_entries_to_delete LIKE rt_reference_list.
    LOOP AT rt_reference_list ASSIGNING <ls_reference_list>.

      " Para las referencias a clases enteras te devuelve todos los subobjetos, que no es lo que queremos en este caso
      IF <ls_reference_list>-reference_fragid = 'R3TR' AND <ls_reference_list>-reference_fragment = 'CLAS'.
        CONTINUE.
      ENDIF.

      DATA(ls_cross_reference) = VALUE cnvcdmccts_objs_ref( ).
      ls_cross_reference-ref_pgmid    = <ls_reference_list>-reference_fragid.
      ls_cross_reference-ref_obj_name = <ls_reference_list>-reference_fragname.
      ls_cross_reference-ref_obj_type = <ls_reference_list>-reference_fragment.

      DATA(lt_cross_reference) = VALUE ty_t_objs_ref_tab( ( ls_cross_reference ) ).
      DATA(lt_cross_reference_changed) = VALUE ty_t_objs_ref_tab( ).
      PERFORM convert_ref_objects IN PROGRAM /sdf/saplteap_main
        TABLES lt_cross_reference
               lt_cross_reference_changed
        USING  'NONE'
               ai_rfc_destination.

      FINAL(lv_lines) = lines( lt_cross_reference_changed ).
      IF lv_lines = 0.
        CONTINUE.
      ENDIF.

      FINAL(lv_ref_name) = lt_cross_reference_changed[ lv_lines ]-ref_obj_name.
      FINAL(lv_ref_pgimd) = lt_cross_reference_changed[ lv_lines ]-ref_pgmid.
      FINAL(lv_ref_type) = lt_cross_reference_changed[ lv_lines ]-ref_obj_type.

      ASSIGN rt_reference_list[ reference_fragname = lv_ref_name
                                reference_fragment = lv_ref_type
                                reference_fragid   = lv_ref_pgimd ] TO FIELD-SYMBOL(<ls_new_reference_list>) ELSE UNASSIGN.
      IF <ls_new_reference_list> IS NOT ASSIGNED.
        <ls_reference_list>-reference_fragname = lv_ref_name.
        <ls_reference_list>-reference_fragid   = lv_ref_pgimd.
        <ls_reference_list>-reference_fragment = lv_ref_type.

        CONTINUE.
      ENDIF.

      INSERT LINES OF <ls_reference_list>-object_list INTO TABLE <ls_new_reference_list>-object_list.
      SORT <ls_new_reference_list>-object_list.
      DELETE ADJACENT DUPLICATES FROM <ls_new_reference_list>-object_list.

      IF <ls_reference_list>-reference_fragid = 'LIMU' AND <ls_reference_list>-reference_fragment = 'METH'.
        INSERT <ls_reference_list> INTO TABLE lt_entries_to_delete.
      ENDIF.

    ENDLOOP.

    " Delete entries
    " For example,  LIMU METH to interface methods
    IF lt_entries_to_delete IS NOT INITIAL.
      lt_range_to_delete = VALUE #( FOR ls_entries_to_delete IN lt_entries_to_delete
                                    ( sign = 'I' option = 'EQ' low = ls_entries_to_delete-reference_fragname ) ).
      DELETE rt_reference_list WHERE     reference_fragid    = 'LIMU'
                                     AND reference_fragment  = 'METH'
                                     AND reference_fragname IN lt_range_to_delete.
    ENDIF.

    " Delete R3TR CLASS from object_list
    LOOP AT rt_reference_list ASSIGNING <ls_reference_list>.
      DELETE <ls_reference_list>-object_list WHERE pgmid = 'R3TR' AND type = 'CLAS'.
    ENDLOOP.
  ENDMETHOD.

  METHOD check_if_in_transport_request.
    rt_reference_list = it_result.
    LOOP AT rt_reference_list ASSIGNING FIELD-SYMBOL(<ls_reference_list>) WHERE status IS INITIAL.

      IF <ls_reference_list>-reference_fragid = 'R3TR' AND <ls_reference_list>-reference_fragment = 'CLAS'.

        ASSIGN it_importing_objects[ pgmid    = 'LIMU'
                                     obj_type = 'CLSD'
                                     obj_name = <ls_reference_list>-reference_fragname ] TO FIELD-SYMBOL(<ls_importing_objects>) ELSE UNASSIGN.
        IF <ls_importing_objects> IS NOT ASSIGNED.
          CONTINUE.
        ENDIF.

        <ls_reference_list>-status = yif_trm_cross_reference=>c_status-also_in_transport_request.
        CONTINUE.

      ENDIF.

      IF <ls_reference_list>-reference_fragment = 'FUNC' AND (    <ls_reference_list>-reference_fragname CP 'DEQUEUE_*'
                                                               OR <ls_reference_list>-reference_fragname CP 'ENQUEUE_*' ).

        FINAL(lv_lock_object_name) = <ls_reference_list>-reference_fragname+8.
        IF line_exists( it_importing_objects[ pgmid    = 'R3TR'
                                              obj_type = 'ENQU'
                                              obj_name = lv_lock_object_name ] ).

        ENDIF.
        <ls_reference_list>-status = yif_trm_cross_reference=>c_status-also_in_transport_request.
        CONTINUE.
      ENDIF.

      ASSIGN it_importing_objects[ pgmid    = <ls_reference_list>-reference_fragid
                                   obj_type = <ls_reference_list>-reference_fragment
                                   obj_name = <ls_reference_list>-reference_fragname ] TO <ls_importing_objects> ELSE UNASSIGN.
      IF <ls_importing_objects> IS NOT ASSIGNED.
        CONTINUE.
      ENDIF.

      <ls_reference_list>-status = yif_trm_cross_reference=>c_status-also_in_transport_request.

    ENDLOOP.
  ENDMETHOD.

  METHOD check_against_rfc.
    DATA lt_comparison TYPE vrs_compare_item_tab.
    " TODO: variable is assigned but never used (ABAP cleaner)
    DATA ls_rfcsi_a    TYPE rfcsi.
    " TODO: variable is assigned but never used (ABAP cleaner)
    DATA ls_rfcsi_b    TYPE rfcsi.
    " TODO: variable is assigned but never used (ABAP cleaner)
    DATA lt_nonvers    TYPE TABLE OF e071.

    DATA(lt_objects) = VALUE scwb_t_e071( FOR is_reference_list IN it_result WHERE ( status IS INITIAL )
                                          ( pgmid    = is_reference_list-reference_fragid
                                            object   = is_reference_list-reference_fragment
                                            obj_name = is_reference_list-reference_fragname ) ).

    " Quitamos los paquetes porque al comparar trae todos los objetos que contienen...
    DELETE lt_objects WHERE object = 'DEVC'.

    " Eliminamos las entradas de customizing para la comparación
    DELETE lt_objects WHERE objfunc = yif_trm_tr_object=>function-customizing.

    " Eliminamos las entradas marcadas como borradas para la comparación
    DELETE lt_objects WHERE objfunc = yif_trm_tr_object=>function-deleted.

    FINAL(lv_filter_lang) = abap_true.
    FINAL(lv_delete_lang) = ' '.
    CALL FUNCTION 'SVRS_MASSCOMPARE_ACT_OBJECTS'
      EXPORTING  it_e071                = lt_objects
*                 IV_RFCDEST_A           =
                 iv_rfcdest_b           = ai_rfc_destination
                 iv_filter_lang         = lv_filter_lang
                 iv_delete_lang         = lv_delete_lang
*                 IV_ABAP_IGNORE_CASE    = 'X'
*                 IV_ABAP_CONDENSE       = 'X'
*                 IV_ABAP_IGNORE_COMMENTS = 'X'
*                 IV_ABAP_EQUIVALENCE    = 'X'
                 iv_with_gui_progress   = abap_false
                 iv_ignore_report_text  = 'X'
      IMPORTING  et_compare_items       = lt_comparison
                 es_rfcsi_a             = ls_rfcsi_a
                 es_rfcsi_b             = ls_rfcsi_b
                 et_nonversionable_e071 = lt_nonvers
      EXCEPTIONS rfc_error              = 1
                 not_supported          = 2
                 OTHERS                 = 3.
    CASE sy-subrc.
      WHEN 0.
      WHEN 1.
        MESSAGE i008(tsys) WITH ai_rfc_destination.
        FINAL(lx_tr) = NEW ycx_trm_transport_request( ).
        RAISE EXCEPTION lx_tr.
      WHEN OTHERS.
        MESSAGE i015(tsys).
    ENDCASE.

    " Not comparable = 'X' es que no existe en destino...

    rt_reference_list = it_result.
    LOOP AT rt_reference_list ASSIGNING FIELD-SYMBOL(<ls_reference_list>) WHERE status IS INITIAL AND reference_fragment <> 'DEVC'.

      IF <ls_reference_list>-reference_fragid = 'R3TR' AND <ls_reference_list>-reference_fragment = 'CLAS'.

        " Del R3TR class solo me interesa si existe o no
        <ls_reference_list>-status = yif_trm_cross_reference=>c_status-exist_in_destination.
        IF VALUE #( lt_comparison[ fragid   = 'LIMU'
                                   fragment = 'CLSD'
                                   fragname = <ls_reference_list>-reference_fragname ]-not_comparable OPTIONAL ) = abap_true.
          <ls_reference_list>-status = yif_trm_cross_reference=>c_status-only_in_source.
        ENDIF.

        CONTINUE.

      ENDIF.

      IF VALUE #( lt_comparison[ fragid   = <ls_reference_list>-reference_fragid
                                 fragment = <ls_reference_list>-reference_fragment
                                 fragname = <ls_reference_list>-reference_fragname ]-not_comparable OPTIONAL ) = abap_true.
        <ls_reference_list>-status = yif_trm_cross_reference=>c_status-only_in_source.
        CONTINUE.
      ENDIF.

      IF VALUE #( lt_comparison[ fragid   = <ls_reference_list>-reference_fragid
                                 fragment = <ls_reference_list>-reference_fragment
                                 fragname = <ls_reference_list>-reference_fragname ]-equal OPTIONAL ) = abap_true.
        <ls_reference_list>-status = yif_trm_cross_reference=>c_status-equal_in_destination.
        CONTINUE.
      ENDIF.

      <ls_reference_list>-status = yif_trm_cross_reference=>c_status-different_in_destination.

    ENDLOOP.
  ENDMETHOD.

  METHOD check_not_sap_object.
    DATA ls_tadir     TYPE tadir.
    DATA lv_namespace TYPE trnspace-namespace.

    rt_reference_list = it_result.

    LOOP AT rt_reference_list ASSIGNING FIELD-SYMBOL(<ls_reference_list>) WHERE status IS INITIAL.

      PERFORM get_namespace IN PROGRAM /sdf/saplteap_main
        USING    <ls_reference_list>-reference_fragid
                 <ls_reference_list>-reference_fragment
                 <ls_reference_list>-reference_fragname
                 'NONE'
        CHANGING ls_tadir
                 lv_namespace.
      IF lv_namespace <> '/0SAP/'.
        CONTINUE.
      ENDIF.

      <ls_reference_list>-status = yif_trm_cross_reference=>c_status-sap_reference.

    ENDLOOP.
  ENDMETHOD.

  METHOD get_with_fragments.
    TYPES ty_t_e071 TYPE STANDARD TABLE OF e071 WITH DEFAULT KEY.

    DATA lt_comparison TYPE vrs_compare_item_tab.
    DATA lt_nonvers    TYPE TABLE OF e071.

    FINAL(lv_filter_lang) = abap_true.
    FINAL(lv_delete_lang) = ' '.

    DATA(lt_objects_to_compare) = it_objects.
    DELETE lt_objects_to_compare WHERE obj_type = 'DEVC'. "<-- Los paquetes devuelve todo el contenido, no es necesario

    CALL FUNCTION 'SVRS_MASSCOMPARE_ACT_OBJECTS'
      EXPORTING  it_e071                = CORRESPONDING ty_t_e071( lt_objects_to_compare MAPPING object = obj_type )
*                 IV_RFCDEST_A           =
                 iv_rfcdest_b           = 'NONE'
                 iv_filter_lang         = lv_filter_lang
                 iv_delete_lang         = lv_delete_lang
*                 IV_ABAP_IGNORE_CASE    = 'X'
*                 IV_ABAP_CONDENSE       = 'X'
*                 IV_ABAP_IGNORE_COMMENTS = 'X'
*                 IV_ABAP_EQUIVALENCE    = 'X'
                 iv_with_gui_progress   = abap_false
                 iv_ignore_report_text  = 'X'
      IMPORTING  et_compare_items       = lt_comparison
*                 es_rfcsi_a             = ls_rfcsi_a
*                 es_rfcsi_b             = ls_rfcsi_b
                 et_nonversionable_e071 = lt_nonvers
      EXCEPTIONS rfc_error              = 1
                 not_supported          = 2
                 OTHERS                 = 3.
    CASE sy-subrc.
      WHEN 0.
      WHEN 1.
        MESSAGE i008(tsys) WITH ai_rfc_destination.
        FINAL(lx_tr) = NEW ycx_trm_transport_request( ).
        RAISE EXCEPTION lx_tr.
      WHEN OTHERS.
        MESSAGE i015(tsys).
    ENDCASE.

    rt_result = it_objects.

    rt_result = VALUE #( BASE rt_result FOR ls_comparison IN lt_comparison
                         ( pgmid    = ls_comparison-fragid
                           obj_type = ls_comparison-fragment
                           obj_name = ls_comparison-fragname ) ).

    rt_result = VALUE #( BASE rt_result FOR ls_nonvers IN lt_nonvers
                         ( pgmid    = ls_nonvers-pgmid
                           obj_type = ls_nonvers-object
                           obj_name = ls_nonvers-obj_name ) ).

    SORT rt_result.
    DELETE ADJACENT DUPLICATES FROM rt_result.
  ENDMETHOD.

  METHOD check_methods.
    rt_reference_list = it_result.

    LOOP AT rt_reference_list ASSIGNING FIELD-SYMBOL(<ls_reference_list>) WHERE     status             IS INITIAL
                                                                                AND reference_fragment  = 'METH'.

      FINAL(lo_method_cross_ref) = CAST ycl_trm_cross_reference_meth( ycl_trm_cross_ref=>create( <ls_reference_list> ) ).

      TRY.
          FINAL(ls_method_descr_in_currnt_syst) = lo_method_cross_ref->describe( ).
        CATCH ycx_trm_transport_request.
      ENDTRY.

      " Validamos si existe en destino
      IF lo_method_cross_ref->exists( ai_rfc_destination ).
        <ls_reference_list>-status = yif_trm_cross_reference=>c_status-exist_in_destination.
        CONTINUE.
      ENDIF.

      " Esto solo aplica si está definido en una clase, no en una interfaz
      IF ls_method_descr_in_currnt_syst-defined_in-object_type = 'CLAS'.
        IF NOT (    line_exists( <ls_reference_list>-object_list[ type = 'CPUB' ] )
                 OR line_exists( <ls_reference_list>-object_list[ type = 'CPRO' ] )
                 OR line_exists( <ls_reference_list>-object_list[ type = 'CPRI' ] ) ).

          <ls_reference_list>-status = yif_trm_cross_reference=>c_status-definition_missing.
          CONTINUE.

        ENDIF.
      ENDIF.

      " Validamos si la implementación está en la orden ( puede venir con clas+alias o clas+intf~name o clas+intf~alias o clas+name )
      DATA(lv_fragname) = <ls_reference_list>-reference_fragname.
      SPLIT <ls_reference_list>-reference_fragname+30 AT '~' INTO FINAL(lv_interface_or_method_name) FINAL(lv_method_name_or_empty).
      DATA(lv_method_name) = lv_method_name_or_empty.
      IF lv_method_name IS INITIAL.
        lv_method_name = lv_interface_or_method_name.
      ENDIF.

      IF lv_method_name IS NOT INITIAL.
        lv_fragname = |{ <ls_reference_list>-reference_fragname(30) }|.
        lv_fragname+30 = |{ ls_method_descr_in_currnt_syst-defined_in-object_name }~{ lv_method_name }|.
      ENDIF.

      IF NOT line_exists( ai_t_order_fragments[ pgmid    = <ls_reference_list>-reference_fragid
                                                obj_name = lv_fragname
                                                obj_type = <ls_reference_list>-reference_fragment ] ).

        <ls_reference_list>-status = yif_trm_cross_reference=>c_status-only_in_source.
        CONTINUE.
      ENDIF.

      " Validamos is la definición está en la orden
      IF line_exists( ai_t_order_fragments[ pgmid    = ls_method_descr_in_currnt_syst-defined_in-object_pgmid
                                            obj_name = ls_method_descr_in_currnt_syst-defined_in-object_name
                                            obj_type = ls_method_descr_in_currnt_syst-defined_in-object_type ] ).

        <ls_reference_list>-status = yif_trm_cross_reference=>c_status-also_in_transport_request.
        CONTINUE.
      ENDIF.

      " Validamos si hay cambios
      FINAL(lt_comparison) = lo_method_cross_ref->compare( ai_rfc_destination ).

      " TODO: variable is assigned but never used (ABAP cleaner)
      LOOP AT lt_comparison ASSIGNING FIELD-SYMBOL(<ls_comparison>) WHERE severity <> icon_led_green.
        <ls_reference_list>-status = yif_trm_cross_reference=>c_status-method_definition_dif_in_dest.
        EXIT.
      ENDLOOP.
      IF sy-subrc <> 0.
        <ls_reference_list>-status = yif_trm_cross_reference=>c_status-equal_in_destination.
      ENDIF.

    ENDLOOP.
  ENDMETHOD.

  METHOD check_interfaces.
    DATA lt_interface_cross_reference LIKE it_cross_reference.

    rt_result = it_result.

    LOOP AT rt_result ASSIGNING FIELD-SYMBOL(<ls_result>) WHERE     reference_fragid   = 'R3TR'
                                                                AND reference_fragment = 'INTF'
                                                                AND status             = yif_trm_cross_reference=>c_status-different_in_destination.

      " Get interface reference
      CLEAR lt_interface_cross_reference.
      LOOP AT it_cross_reference ASSIGNING FIELD-SYMBOL(<ls_cross_reference>) WHERE    ref_obj_name CP |{ <ls_result>-reference_fragname }~*|
                                                                                    OR ref_obj_name  = <ls_result>-reference_fragname.

        IF NOT line_exists( <ls_result>-object_list[ name = <ls_cross_reference>-obj_name
                                                     type = <ls_cross_reference>-obj_type ] ).
          CONTINUE.
        ENDIF.

        INSERT <ls_cross_reference> INTO TABLE lt_interface_cross_reference.

      ENDLOOP.

      " Las referencias a la propia interfaz no las analizamos puesto que la interfaz existe en destino y no habra problema en crear una referencia
      DELETE lt_interface_cross_reference WHERE     ref_obj_name = <ls_result>-reference_fragname
                                                AND ref_obj_type = 'INTF'.

      " Describe interface in destination system
      TRY.
          FINAL(lt_descr_destination_system) = CAST ycl_trm_cross_reference_obj( ycl_trm_cross_ref=>create( <ls_result> ) )->describe(
              ai_rfc_destination ).
        CATCH ycx_trm_transport_request.
      ENDTRY.

      " De cada uno del uso, buscamos exactametne que se está usando y si no existe en destino, damos error
      <ls_result>-status = yif_trm_cross_reference=>c_status-different_but_not_relevant.
      LOOP AT <ls_result>-object_list ASSIGNING FIELD-SYMBOL(<ls_object_list>).

        " Las referencias que no estan en "lt_interface_cross_reference" es porque son al R3TR INTF que en este punto seguro que existe en destino
        <ls_object_list>-severity = icon_led_green.

        LOOP AT lt_interface_cross_reference ASSIGNING FIELD-SYMBOL(<ls_interface_cross_reference>) WHERE     obj_name = <ls_object_list>-name
                                                                                                          AND obj_type = <ls_object_list>-type
                                                                                                          AND pgmid    = <ls_object_list>-pgmid.

          DATA(lv_interface_ref_obj_name) = <ls_interface_cross_reference>-ref_obj_name.
          REPLACE ALL OCCURRENCES OF |{ <ls_result>-reference_fragname }~| IN lv_interface_ref_obj_name WITH space.

          IF line_exists( lt_descr_destination_system[ sub_object_type = <ls_interface_cross_reference>-ref_obj_type
                                                       sub_object_name = lv_interface_ref_obj_name ] ).
            CONTINUE.
          ENDIF.

          IF line_exists( lt_descr_destination_system[
                              sub_object_type       = <ls_interface_cross_reference>-ref_obj_type
                              sub_object_name_alias = lv_interface_ref_obj_name ] ).
            CONTINUE.
          ENDIF.

          <ls_object_list>-severity = icon_led_red.
          IF <ls_object_list>-logger IS NOT BOUND.
            <ls_object_list>-logger = ycl_trm_logger=>new( ).
          ENDIF.
          <ls_object_list>-logger->add_text(
              |{ <ls_interface_cross_reference>-ref_obj_type } { <ls_interface_cross_reference>-ref_obj_name } not exists in destination| ).

          <ls_result>-status = yif_trm_cross_reference=>c_status-different.

        ENDLOOP.

      ENDLOOP.

    ENDLOOP.
  ENDMETHOD.

  METHOD check_cpub_cpro_cpri.
    " TODO: parameter IT_CROSS_REFERENCE is never used (ABAP cleaner)

    DATA lt_r_fragment TYPE RANGE OF trobjtype.

    lt_r_fragment = VALUE #( sign   = 'I'
                             option = 'EQ'
                             ( low = 'CPUB' )
                             ( low = 'CPRO' )
                             ( low = 'CPRI' ) ).

    rt_result = it_result.

    LOOP AT rt_result ASSIGNING FIELD-SYMBOL(<ls_result>) WHERE     reference_fragid    = 'LIMU'
                                                                AND reference_fragment IN lt_r_fragment
                                                                AND status              = yif_trm_cross_reference=>c_status-different_in_destination.

      <ls_result>-status = yif_trm_cross_reference=>c_status-different_but_not_relevant.

      " Validar que existe la definicion en destino
      LOOP AT <ls_result>-object_list ASSIGNING FIELD-SYMBOL(<ls_method_being_transported>) WHERE type = 'METH'.

        " Validar que la definición del método exista en destino
        FINAL(lo_method_cross_ref) = CAST ycl_trm_cross_reference_meth( ycl_trm_cross_ref=>create(
                                                                            VALUE #(
                                                                                reference_fragid   = 'LIMU'
                                                                                reference_fragment = 'METH'
                                                                                reference_fragname = <ls_method_being_transported>-name ) ) ).

        " Validamos si existe en destino
        IF lo_method_cross_ref->exists( ai_rfc_destination ).
          CONTINUE.
        ENDIF.

        <ls_method_being_transported>-severity = icon_led_red.
        <ls_method_being_transported>-logger   = ycl_trm_logger=>new( ).
        <ls_method_being_transported>-logger->error( |Definition Missing| ).

        <ls_result>-status = yif_trm_cross_reference=>c_status-different.

      ENDLOOP.

    ENDLOOP.
  ENDMETHOD.

  METHOD check_devc.
    rt_result = it_result.

    LOOP AT rt_result ASSIGNING FIELD-SYMBOL(<ls_reference_list>) WHERE     status             IS INITIAL
                                                                        AND reference_fragment  = 'DEVC'.

      DATA(lv_exist) = abap_false.
      CALL FUNCTION 'YTRM_FM_CROSS_REF_EXISTS' DESTINATION ai_rfc_destination
        EXPORTING iv_pgmid    = <ls_reference_list>-reference_fragid
                  iv_object   = <ls_reference_list>-reference_fragment
                  iv_obj_name = <ls_reference_list>-reference_fragname
        IMPORTING e_exist     = lv_exist.

      <ls_reference_list>-status = yif_trm_cross_reference=>c_status-only_in_source.
      IF lv_exist = abap_true.
        <ls_reference_list>-status = yif_trm_cross_reference=>c_status-exist_in_destination.
      ENDIF.

    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
