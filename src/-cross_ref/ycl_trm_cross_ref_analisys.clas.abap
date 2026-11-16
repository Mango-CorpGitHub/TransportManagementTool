CLASS ycl_trm_cross_ref_analisys DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES ty_t_objects      TYPE yif_trm_xref_repository=>ty_t_objects.
    TYPES ty_t_objs_ref_tab TYPE yif_trm_xref_repository=>ty_t_references.

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

    "! @parameter iv_rfc_comparison | Destination system
    "! @parameter io_repository | Local repository access; real one if not supplied
    "! @parameter io_source_system | Local system; real one if not supplied
    "! @parameter io_destination_system | Destination system; real one if not supplied
    METHODS constructor
      IMPORTING iv_rfc_comparison        TYPE rfcdes-rfcdest
                io_repository            TYPE REF TO yif_trm_xref_repository OPTIONAL
                io_source_system         TYPE REF TO yif_trm_xref_system     OPTIONAL
                io_destination_system    TYPE REF TO yif_trm_xref_system     OPTIONAL.

  PRIVATE SECTION.
    DATA ai_o_repository         TYPE REF TO yif_trm_xref_repository.
    DATA ai_o_source_system      TYPE REF TO yif_trm_xref_system.
    DATA ai_o_destination_system TYPE REF TO yif_trm_xref_system.
    DATA ai_o_factory            TYPE REF TO ycl_trm_xref_reference_factory.
    DATA ai_t_order_fragments    TYPE ycl_trm_cross_ref_analisys=>ty_t_objects.

    METHODS prepare_importing_objects
      IMPORTING it_objects        TYPE ty_t_objects
      RETURNING VALUE(rs_objects) TYPE ty_s_pre_object_analisys.

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
      RETURNING VALUE(rt_reference_list) TYPE ycl_trm_cross_ref_analisys=>ty_t_result
      RAISING   ycx_trm_cross_reference.

    METHODS check_not_sap_object
      IMPORTING it_result                TYPE ycl_trm_cross_ref_analisys=>ty_t_result
      RETURNING VALUE(rt_reference_list) TYPE ycl_trm_cross_ref_analisys=>ty_t_result.

    METHODS get_with_fragments
      IMPORTING it_objects       TYPE ycl_trm_cross_ref_analisys=>ty_t_objects
      RETURNING VALUE(rt_result) TYPE ycl_trm_cross_ref_analisys=>ty_t_objects
      RAISING   ycx_trm_cross_reference.

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
    ai_o_repository = COND #( WHEN io_repository IS BOUND
                              THEN io_repository
                              ELSE NEW ycl_trm_xref_repository( iv_rfc_comparison ) ).

    ai_o_source_system = COND #( WHEN io_source_system IS BOUND
                                 THEN io_source_system
                                 ELSE NEW ycl_trm_cross_ref_describe_obj( 'NONE' ) ).

    ai_o_destination_system = COND #( WHEN io_destination_system IS BOUND
                                      THEN io_destination_system
                                      ELSE NEW ycl_trm_cross_ref_describe_obj( iv_rfc_comparison ) ).

    ai_o_factory = NEW #( io_source_system      = ai_o_source_system
                          io_destination_system = ai_o_destination_system ).
  ENDMETHOD.

  METHOD run.
*------------------------------------------------
* Get dependencies
*------------------------------------------------

    ai_t_order_fragments = get_with_fragments( it_objects ).

    DATA(ls_request_objets_resume) = prepare_importing_objects( ai_t_order_fragments ).

    DATA(lt_cross_reference) = get_cross_reference( ls_request_objets_resume-analyzed_objects ).
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
                                                                ( ai_o_factory->create( ls_result ) ) ) ).
  ENDMETHOD.

  METHOD get_cross_reference.
    DATA(lt_objects) = it_objects.
    IF lt_objects IS INITIAL.
      DATA(lo_log) = ycl_trm_logger=>new( ).
      MESSAGE s019(ytrm) INTO DATA(lv_message) ##NEEDED.
      lo_log->add_message( CORRESPONDING #( sy ) ).
      RAISE EXCEPTION NEW ycx_trm_cross_reference( logger = lo_log ).
      RETURN.
    ENDIF.

    rt_cross_reference = ai_o_repository->get_references( lt_objects ).

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

    " Esta funcion da dump si el método está definido en una interfaz
    lt_methods = ai_o_repository->resolve_methods( lt_methods ).

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
                INTO DATA(lv_intf_name) DATA(lv_meth_obj_name).

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

      DATA(lt_class_part_methods) = ai_o_repository->get_class_part_methods(
                                         iv_part       = <ls_class_part>-obj_type
                                         iv_class_name = <ls_class_part>-obj_name ).

      LOOP AT lt_class_part_methods ASSIGNING FIELD-SYMBOL(<lv_class_part_method>).

        INSERT VALUE cnvcdmccts_objs_ref( pgmid        = <ls_class_part>-pgmid
                                          obj_type     = <ls_class_part>-obj_type
                                          obj_name     = <ls_class_part>-obj_name
                                          ref_pgmid    = 'LIMU'
                                          ref_obj_type = 'METH'
                                          ref_obj_name = |{ <ls_class_part>-obj_name }~{ <lv_class_part_method> }| )
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
                'CPUB CPRI CPRO CLSD DYNP FUGR DDLS TRAN ENHO VKOS CFDF' INTO DATA(lv_supported_types_string)
                SEPARATED BY space.

    SPLIT lv_supported_types_string AT space INTO TABLE DATA(lt_suported_types).
    LOOP AT lt_objects INTO DATA(ls_objects).

      IF NOT line_exists( lt_suported_types[ table_line = ls_objects-obj_type ] ).
        INSERT ls_objects INTO TABLE rs_objects-not_analyzed_objects.
        CONTINUE.
      ENDIF.

      IF ai_o_repository->is_sap_object( ls_objects ).
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

    RETURN ai_o_repository->method_exists( iv_class_name  = lv_cls_name2
                                           iv_method_name = lv_meth_name2 ).
  ENDMETHOD.

  METHOD build_reference_list.
    " Add Objects:

    DATA lt_range_to_delete TYPE RANGE OF yif_trm_cross_reference=>ty_s_result-reference_fragname.

    LOOP AT it_cross_reference ASSIGNING FIELD-SYMBOL(<ls_cross_reference>).

      IF NOT ai_o_repository->has_own_pgmid( <ls_cross_reference>-ref_obj_type ).
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

      DATA(lt_cross_reference_changed) = ai_o_repository->normalize_reference( ls_cross_reference ).

      DATA(lv_lines) = lines( lt_cross_reference_changed ).
      IF lv_lines = 0.
        CONTINUE.
      ENDIF.

      DATA(lv_ref_name) = lt_cross_reference_changed[ lv_lines ]-ref_obj_name.
      DATA(lv_ref_pgimd) = lt_cross_reference_changed[ lv_lines ]-ref_pgmid.
      DATA(lv_ref_type) = lt_cross_reference_changed[ lv_lines ]-ref_obj_type.

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

        " The lock module is generated from the lock object: only the lock object has to be checked
        DATA(lv_lock_object_name) = <ls_reference_list>-reference_fragname+8.
        IF line_exists( it_importing_objects[ pgmid    = 'R3TR'
                                              obj_type = 'ENQU'
                                              obj_name = lv_lock_object_name ] ).
          <ls_reference_list>-status = yif_trm_cross_reference=>c_status-also_in_transport_request.
        ELSEIF ai_o_destination_system->object_exists( iv_pgmid    = 'R3TR'
                                                       iv_object   = 'ENQU'
                                                       iv_obj_name = CONV #( lv_lock_object_name ) ).
          <ls_reference_list>-status = yif_trm_cross_reference=>c_status-exist_in_destination.
        ELSE.
          <ls_reference_list>-status = yif_trm_cross_reference=>c_status-only_in_source.
        ENDIF.
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

    FINAL(lt_comparison) = ai_o_destination_system->compare_versions( lt_objects ).

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

    rt_reference_list = it_result.
    LOOP AT rt_reference_list ASSIGNING FIELD-SYMBOL(<ls_reference_list>) WHERE status IS INITIAL.

      IF ai_o_repository->is_sap_object( VALUE #( obj_name = <ls_reference_list>-reference_fragname
                                 pgmid    = <ls_reference_list>-reference_fragid
                                 obj_type = <ls_reference_list>-reference_fragment ) ).

        <ls_reference_list>-status = yif_trm_cross_reference=>c_status-sap_reference.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD get_with_fragments.
    DATA(lt_objects_to_compare) = it_objects.
    DELETE lt_objects_to_compare WHERE obj_type = 'DEVC'. "<-- Los paquetes devuelve todo el contenido, no es necesario

    rt_result = it_objects.

    INSERT LINES OF ai_o_repository->get_fragments( lt_objects_to_compare ) INTO TABLE rt_result.

    SORT rt_result.
    DELETE ADJACENT DUPLICATES FROM rt_result.
  ENDMETHOD.

  METHOD check_methods.
    rt_reference_list = it_result.

    LOOP AT rt_reference_list ASSIGNING FIELD-SYMBOL(<ls_reference_list>) WHERE     status             IS INITIAL
                                                                                AND reference_fragment  = 'METH'.

      DATA(lo_method_cross_ref) = CAST ycl_trm_cross_reference_meth( ai_o_factory->create( <ls_reference_list> ) ).

      TRY.
          DATA(ls_method_descr_in_currnt_syst) = lo_method_cross_ref->describe( ).
        CATCH ycx_trm_cross_reference.
      ENDTRY.

      " Validamos si existe en destino
      IF lo_method_cross_ref->exists( ).
        <ls_reference_list>-status = yif_trm_cross_reference=>c_status-exist_in_destination.

        " Validamos si hay cambios en la definicion, para comprobar que no nos falte ningún parametro importing o algo
        IF line_exists( ai_t_order_fragments[ pgmid    = ls_method_descr_in_currnt_syst-defined_in-object_pgmid
                                              obj_name = ls_method_descr_in_currnt_syst-defined_in-object_name
                                              obj_type = ls_method_descr_in_currnt_syst-defined_in-object_type ] ).

          <ls_reference_list>-status = yif_trm_cross_reference=>c_status-definition_also_in_trans_req.
          CONTINUE.
        ENDIF.

        DATA(lt_comparison) = lo_method_cross_ref->compare( ).
        <ls_reference_list>-status = COND #( WHEN line_exists( lt_comparison[ severity = icon_led_red ] ) THEN
                                               yif_trm_cross_reference=>c_status-method_def_dif_in_dest_w_err
                                             WHEN line_exists( lt_comparison[ severity = icon_led_yellow ] ) THEN
                                               yif_trm_cross_reference=>c_status-method_definition_dif_in_dest
                                             ELSE
                                               yif_trm_cross_reference=>c_status-exist_in_destination ).

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
      SPLIT <ls_reference_list>-reference_fragname+30 AT '~' INTO DATA(lv_interface_or_method_name) DATA(lv_method_name_or_empty).
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
      lt_comparison = lo_method_cross_ref->compare( ).
      <ls_reference_list>-status = COND #( WHEN line_exists( lt_comparison[ severity = icon_led_red ] ) THEN
                                             yif_trm_cross_reference=>c_status-method_def_dif_in_dest_w_err
                                           WHEN line_exists( lt_comparison[ severity = icon_led_yellow ] ) THEN
                                             yif_trm_cross_reference=>c_status-method_definition_dif_in_dest
                                           ELSE
                                             yif_trm_cross_reference=>c_status-exist_in_destination ).

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
          DATA(lt_intf_comparison) = CAST ycl_trm_cross_reference_obj( ai_o_factory->create( <ls_result> ) )->yif_trm_cross_reference~compare( ).
          DATA(lt_descr_destination_system) = CAST ycl_trm_cross_reference_obj( ai_o_factory->create( <ls_result> ) )->describe(
              iv_in_destination = abap_true ).
        CATCH ycx_trm_cross_reference.
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

          " Caso de una estructura de constantes... Nos llega que usa la constante, no el campo concreto de la constante.
          " En caso de que haya diferencias entre los campos de la estructura de la constante, marcamos para que revise el usuario si realmente se está usando
          IF <ls_interface_cross_reference>-ref_obj_type = 'ATRB'.

            " Si no existe en el sistema destinto...
            LOOP AT lt_intf_comparison TRANSPORTING NO FIELDS WHERE type = 'ATRB' AND name CP |{ lv_interface_ref_obj_name }*|.
              EXIT.
            ENDLOOP.
            IF sy-subrc <> 0.
              <ls_object_list>-severity = icon_led_red.
              IF <ls_object_list>-logger IS NOT BOUND.
                <ls_object_list>-logger = ycl_trm_logger=>new( ).
              ENDIF.
              <ls_object_list>-logger->add_text(
                  |{ <ls_interface_cross_reference>-ref_obj_type } { <ls_interface_cross_reference>-ref_obj_name } not exists in destination| ).

              <ls_result>-status = yif_trm_cross_reference=>c_status-different.
              CONTINUE.
            ENDIF.

            LOOP AT lt_intf_comparison TRANSPORTING NO FIELDS WHERE type = 'ATRB' AND name CP |{ lv_interface_ref_obj_name }*| AND severity <> icon_led_green.
              EXIT.
            ENDLOOP.
            IF sy-subrc = 0.
              <ls_object_list>-severity = icon_led_yellow.
              IF <ls_object_list>-logger IS NOT BOUND.
                <ls_object_list>-logger = ycl_trm_logger=>new( ).
              ENDIF.

              <ls_object_list>-logger->add_text(
                  im_type = 'W'
                  im_text = |{ <ls_interface_cross_reference>-ref_obj_type } { <ls_interface_cross_reference>-ref_obj_name } must be reviewed| ).

              " Si hay alguno con error, se mantiene el error, sino se marca como warning
              <ls_result>-status = COND #( WHEN <ls_result>-status = yif_trm_cross_reference=>c_status-different
                                           THEN yif_trm_cross_reference=>c_status-different
                                           ELSE yif_trm_cross_reference=>c_status-different_in_destination ).

              CONTINUE.

            ENDIF.

            " Está igual en destino que en origen,
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
        DATA(lo_method_cross_ref) = CAST ycl_trm_cross_reference_meth( ai_o_factory->create(
                                                                           VALUE #(
                                                                               reference_fragid   = 'LIMU'
                                                                               reference_fragment = 'METH'
                                                                               reference_fragname = <ls_method_being_transported>-name ) ) ).

        " Validamos si existe en destino
        IF lo_method_cross_ref->exists( ).
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

      DATA(lv_exist) = ai_o_destination_system->object_exists( iv_pgmid    = <ls_reference_list>-reference_fragid
                                                               iv_object   = <ls_reference_list>-reference_fragment
                                                               iv_obj_name = <ls_reference_list>-reference_fragname ).

      <ls_reference_list>-status = yif_trm_cross_reference=>c_status-only_in_source.
      IF lv_exist = abap_true.
        <ls_reference_list>-status = yif_trm_cross_reference=>c_status-exist_in_destination.
      ENDIF.

    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
