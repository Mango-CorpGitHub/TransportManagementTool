CLASS ycl_trm_xref_repository DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES yif_trm_xref_repository.

    METHODS constructor
      IMPORTING iv_rfc_destination TYPE rfcdes-rfcdest.

  PRIVATE SECTION.
    DATA ai_rfc_destination    TYPE rfcdes-rfcdest.
    DATA ai_namespaces_loaded  TYPE abap_bool.
    DATA ai_t_namespace        TYPE STANDARD TABLE OF /sdf/cmo_namespace_long WITH DEFAULT KEY
                                    WITH NON-UNIQUE SORTED KEY sorted_by_key COMPONENTS namespace.

    METHODS load_namespaces.

    METHODS is_interface
      IMPORTING iv_name          TYPE seoclsname
      RETURNING VALUE(rv_result) TYPE abap_bool.

    "! Include with the source of an object of a request (method, class section, program)
    METHODS object_include
      IMPORTING is_object         TYPE cnvcdmccts_objects_set
      RETURNING VALUE(rv_include) TYPE programm.

ENDCLASS.


CLASS ycl_trm_xref_repository IMPLEMENTATION.

  METHOD constructor.
    ai_rfc_destination = iv_rfc_destination.
  ENDMETHOD.

  METHOD yif_trm_xref_repository~get_fragments.
    TYPES ty_t_e071 TYPE STANDARD TABLE OF e071 WITH DEFAULT KEY.

    DATA lt_comparison TYPE vrs_compare_item_tab.
    DATA lt_nonvers    TYPE TABLE OF e071.

    DATA(lv_filter_lang) = abap_true.
    DATA(lv_delete_lang) = ' '.

    CALL FUNCTION 'SVRS_MASSCOMPARE_ACT_OBJECTS'
      EXPORTING  it_e071                = CORRESPONDING ty_t_e071( it_objects MAPPING object = obj_type )
                 iv_rfcdest_b           = 'NONE'
                 iv_filter_lang         = lv_filter_lang
                 iv_delete_lang         = lv_delete_lang
                 iv_with_gui_progress   = abap_false
                 iv_ignore_report_text  = 'X'
      IMPORTING  et_compare_items       = lt_comparison
                 et_nonversionable_e071 = lt_nonvers
      EXCEPTIONS rfc_error              = 1
                 not_supported          = 2
                 OTHERS                 = 3.
    CASE sy-subrc.
      WHEN 0.
      WHEN 1.
        FINAL(lo_log) = ycl_trm_logger=>new( ).
        MESSAGE i008(tsys) WITH ai_rfc_destination INTO FINAL(lv_message) ##NEEDED.
        lo_log->add_from_system_variables( ).
        RAISE EXCEPTION NEW ycx_trm_cross_reference( logger = lo_log ).
      WHEN OTHERS.
        MESSAGE i015(tsys).
    ENDCASE.

    rt_fragments = VALUE #( FOR ls_comparison IN lt_comparison
                            ( pgmid    = ls_comparison-fragid
                              obj_type = ls_comparison-fragment
                              obj_name = ls_comparison-fragname ) ).

    rt_fragments = VALUE #( BASE rt_fragments
                            FOR ls_nonvers IN lt_nonvers
                            ( pgmid    = ls_nonvers-pgmid
                              obj_type = ls_nonvers-object
                              obj_name = ls_nonvers-obj_name ) ).
  ENDMETHOD.

  METHOD yif_trm_xref_repository~get_references.
    DATA lt_messages TYPE TABLE OF cnvcdmc_messages.

    DATA(lt_objects) = it_objects.

    CALL FUNCTION '/SDF/TEAP_GET_REF_OBJECTS'
      TABLES     it_objs                    = lt_objects
                 it_obj_ref_tab             = rt_references
                 et_messages                = lt_messages
      EXCEPTIONS no_objs_specified_for_anal = 1
                 no_ref_found               = 2
                 OTHERS                     = 3.
  ENDMETHOD.

  METHOD yif_trm_xref_repository~resolve_methods.
    DATA lt_objs TYPE STANDARD TABLE OF cnvcdmccts_objects_set WITH DEFAULT KEY.

    rt_methods = it_methods.

    CALL FUNCTION '/SDF/TEAP_RESOLVE_METH'
      TABLES et_objs = lt_objs
             it_objs = lt_objs
             tt_meth = rt_methods.
  ENDMETHOD.

  METHOD yif_trm_xref_repository~get_class_part_methods.
    DATA lt_seomethod TYPE STANDARD TABLE OF vseomethod WITH DEFAULT KEY.
    DATA lt_seoredef  TYPE STANDARD TABLE OF seoredef WITH DEFAULT KEY.

    DATA(lv_function_name) = |SVRS_GET_VERSION_{ iv_part }_40|.

    CALL FUNCTION lv_function_name
      EXPORTING  object_name           = CONV vrsd-objname( iv_class_name )
                 versno                = CONV vrsd-versno( '00000' )
      TABLES     pvseomethod           = lt_seomethod
                 pseoredef             = lt_seoredef
      EXCEPTIONS no_version            = 1
                 system_failure        = 2
                 communication_failure = 3
                 OTHERS                = 4.

    " Abstract methods have no implementation to check
    rt_methods = VALUE #( FOR ls_seomethod IN lt_seomethod WHERE ( mtdabstrct IS INITIAL )
                          ( CONV #( ls_seomethod-cmpname ) ) ).

    " Rows of an implemented interface (ABSTRACT/FINAL METHODS) have the method name without the interface
    LOOP AT lt_seoredef INTO DATA(ls_seoredef) WHERE mtdabstrct IS INITIAL.
      INSERT COND #( WHEN is_interface( ls_seoredef-refclsname )
                     THEN |{ ls_seoredef-refclsname }~{ ls_seoredef-mtdname }|
                     ELSE CONV #( ls_seoredef-mtdname ) ) INTO TABLE rt_methods.
    ENDLOOP.
  ENDMETHOD.

  METHOD yif_trm_xref_repository~is_abstract_method.
    DATA lv_abstract TYPE seoredef-mtdabstrct.

    DATA(lv_class_name) = CONV seoclsname( iv_method_name(30) ).
    DATA(lv_method_name) = condense( CONV string( iv_method_name+30 ) ).

    IF lv_method_name CS '~'.
      SPLIT lv_method_name AT '~' INTO DATA(lv_interface_name) DATA(lv_interface_method_name).
      SELECT SINGLE mtdabstrct FROM seoredef
        WHERE clsname    = @lv_class_name
          AND refclsname = @lv_interface_name
          AND mtdname    = @lv_interface_method_name
          AND version    = '1'
        INTO @lv_abstract.
    ELSE.
      SELECT SINGLE mtdabstrct FROM seocompodf
        WHERE clsname = @lv_class_name
          AND cmpname = @lv_method_name
          AND version = '1'
        INTO @lv_abstract.
    ENDIF.

    rv_result = xsdbool( lv_abstract = abap_true ).
  ENDMETHOD.

  METHOD yif_trm_xref_repository~get_used_components.
    TYPES: BEGIN OF ty_s_object_include,
             include TYPE programm,
             object  TYPE cnvcdmccts_objects_set,
           END OF ty_s_object_include.

    DATA lt_object_includes TYPE STANDARD TABLE OF ty_s_object_include WITH EMPTY KEY.

    LOOP AT it_objects INTO DATA(ls_object).
      DATA(lv_include) = object_include( ls_object ).
      IF lv_include IS NOT INITIAL.
        INSERT VALUE #( include = lv_include object = ls_object ) INTO TABLE lt_object_includes.
      ENDIF.
    ENDLOOP.
    IF lt_object_includes IS INITIAL.
      RETURN.
    ENDIF.

    " Index entries <entity>\TY:<field> and <entity>\AC:<association>
    SELECT include, name FROM wbcrossgt
      FOR ALL ENTRIES IN @lt_object_includes
      WHERE include = @lt_object_includes-include
        AND ( otype = 'TY' OR otype = 'AC' )
      INTO TABLE @DATA(lt_index).

    LOOP AT lt_index INTO DATA(ls_index).
      SPLIT ls_index-name AT '\' INTO TABLE DATA(lt_parts).
      IF lines( lt_parts ) <> 2.
        CONTINUE.
      ENDIF.

      DATA(lv_component) = substring_after( val = lt_parts[ 2 ] sub = ':' ).

      LOOP AT lt_object_includes INTO DATA(ls_object_include) WHERE include = ls_index-include.
        INSERT VALUE #( pgmid        = ls_object_include-object-pgmid
                        obj_type     = ls_object_include-object-obj_type
                        obj_name     = ls_object_include-object-obj_name
                        ref_obj_type = yif_trm_xref_repository=>c_used_component
                        ref_obj_name = |{ lt_parts[ 1 ] }~{ lv_component }| ) INTO TABLE rt_references.
      ENDLOOP.
    ENDLOOP.

    SORT rt_references.
    DELETE ADJACENT DUPLICATES FROM rt_references.
  ENDMETHOD.

  METHOD yif_trm_xref_repository~has_cds_parameters.
    SELECT SINGLE @abap_true FROM dd10b
      WHERE strucobjn = @iv_cds_name
        AND as4local  = 'A'
      INTO @rv_result.
  ENDMETHOD.

  METHOD object_include.
    CASE is_object-obj_type.
      WHEN 'METH'.
        cl_oo_classname_service=>get_method_include(
          EXPORTING  mtdkey              = VALUE #( clsname = is_object-obj_name(30)
                                                    cpdname = condense( CONV string( is_object-obj_name+30 ) ) )
          RECEIVING  result              = rv_include
          EXCEPTIONS class_not_existing  = 1
                     method_not_existing = 2
                     OTHERS              = 3 ).
        IF sy-subrc <> 0.
          CLEAR rv_include.
        ENDIF.
      WHEN 'CPUB'.
        rv_include = cl_oo_classname_service=>get_pubsec_name( CONV #( is_object-obj_name ) ).
      WHEN 'CPRO'.
        rv_include = cl_oo_classname_service=>get_prosec_name( CONV #( is_object-obj_name ) ).
      WHEN 'CPRI'.
        rv_include = cl_oo_classname_service=>get_prisec_name( CONV #( is_object-obj_name ) ).
      WHEN 'PROG' OR 'REPS'.
        rv_include = is_object-obj_name.
    ENDCASE.
  ENDMETHOD.

  METHOD is_interface.
    SELECT SINGLE @abap_true FROM seoclass
      WHERE clsname = @iv_name
        AND clstype = '1'
      INTO @rv_result.
  ENDMETHOD.

  METHOD yif_trm_xref_repository~has_own_pgmid.
    CALL FUNCTION 'TR_GET_PGMID_FOR_OBJECT'
      EXPORTING  iv_object      = iv_object_type
      EXCEPTIONS illegal_object = 1
                 OTHERS         = 2.

    rv_result = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD yif_trm_xref_repository~normalize_reference.
    DATA(lt_reference) = VALUE yif_trm_xref_repository=>ty_t_references( ( is_reference ) ).
    DATA(lt_normalized) = VALUE yif_trm_xref_repository=>ty_t_references( ).

    PERFORM convert_ref_objects IN PROGRAM /sdf/saplteap_main
      TABLES lt_reference
             lt_normalized
      USING  'NONE'
             ai_rfc_destination.

    rt_normalized = lt_normalized.
  ENDMETHOD.

  METHOD yif_trm_xref_repository~is_sap_object.
    DATA ls_e071      TYPE e071.
    DATA lv_namespace TYPE trnspace-namespace.

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

    IF lv_namespace <> '/0SAP/' AND lv_namespace <> '/0CUST/'.
      load_namespaces( ).
      TRY.
          FINAL(ls_namespace) = ai_t_namespace[ KEY sorted_by_key
                                                namespace = lv_namespace ].
          lv_namespace = COND #( WHEN ls_namespace-ns_info = 'SAP' THEN '/0SAP/' ELSE '/0CUST/' ).
        CATCH cx_sy_itab_line_not_found.
          lv_namespace = '/0CUST/'.
      ENDTRY.
    ENDIF.

    rv_result = xsdbool( lv_namespace = '/0SAP/' ).
  ENDMETHOD.

  METHOD yif_trm_xref_repository~method_exists.
    CALL FUNCTION 'RPY_EXISTENCE_CHECK_METH'
      EXPORTING  class     = iv_class_name
                 method    = iv_method_name
      EXCEPTIONS not_exist = 1.

    rv_result = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD load_namespaces.
    IF ai_namespaces_loaded = abap_true.
      RETURN.
    ENDIF.

    CALL FUNCTION '/SDF/CMO_NAMESPACE_INFO'
      TABLES et_namespace = ai_t_namespace.

    ai_namespaces_loaded = abap_true.
  ENDMETHOD.

ENDCLASS.
