*"* use this source file for your ABAP unit test classes

CLASS ltd_repository DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    INTERFACES yif_trm_xref_repository.

    TYPES: BEGIN OF ty_s_class_part_method,
             part       TYPE trobjtype,
             class_name TYPE trobj_name,
             method     TYPE string,
           END OF ty_s_class_part_method.

    TYPES: BEGIN OF ty_s_normalization,
             ref_pgmid    TYPE pgmid,
             ref_obj_type TYPE trobjtype,
             ref_obj_name TYPE trobj_name,
             normalized   TYPE yif_trm_xref_repository=>ty_t_references,
           END OF ty_s_normalization.

    TYPES: BEGIN OF ty_s_method,
             class_name  TYPE tmdir-classname,
             method_name TYPE tmdir-methodname,
           END OF ty_s_method.

    DATA fragments           TYPE yif_trm_xref_repository=>ty_t_objects.
    DATA references          TYPE yif_trm_xref_repository=>ty_t_references.
    DATA resolved_methods    TYPE yif_trm_xref_repository=>ty_t_objects.
    DATA class_part_methods  TYPE STANDARD TABLE OF ty_s_class_part_method WITH EMPTY KEY.
    DATA types_without_pgmid TYPE STANDARD TABLE OF trobjtype WITH EMPTY KEY.
    DATA normalizations      TYPE STANDARD TABLE OF ty_s_normalization WITH EMPTY KEY.
    DATA sap_objects         TYPE yif_trm_xref_repository=>ty_t_objects.
    DATA missing_methods     TYPE STANDARD TABLE OF ty_s_method WITH EMPTY KEY.
    DATA abstract_methods    TYPE STANDARD TABLE OF trobj_name WITH EMPTY KEY.
    DATA used_components     TYPE yif_trm_xref_repository=>ty_t_references.
    DATA cds_with_parameters TYPE STANDARD TABLE OF trobj_name WITH EMPTY KEY.

ENDCLASS.


CLASS ltd_repository IMPLEMENTATION.

  METHOD yif_trm_xref_repository~get_fragments.
    rt_fragments = fragments.
  ENDMETHOD.

  METHOD yif_trm_xref_repository~get_references.
    rt_references = references.
  ENDMETHOD.

  METHOD yif_trm_xref_repository~get_used_components.
    rt_references = used_components.
  ENDMETHOD.

  METHOD yif_trm_xref_repository~has_cds_parameters.
    rv_result = xsdbool( line_exists( cds_with_parameters[ table_line = iv_cds_name ] ) ).
  ENDMETHOD.

  METHOD yif_trm_xref_repository~resolve_methods.
    rt_methods = COND #( WHEN resolved_methods IS INITIAL THEN it_methods ELSE resolved_methods ).
  ENDMETHOD.

  METHOD yif_trm_xref_repository~get_class_part_methods.
    rt_methods = VALUE #( FOR ls_method IN class_part_methods
                          WHERE ( part = iv_part AND class_name = iv_class_name )
                          ( ls_method-method ) ).
  ENDMETHOD.

  METHOD yif_trm_xref_repository~has_own_pgmid.
    rv_result = xsdbool( NOT line_exists( types_without_pgmid[ table_line = iv_object_type ] ) ).
  ENDMETHOD.

  METHOD yif_trm_xref_repository~normalize_reference.
    rt_normalized = VALUE #( normalizations[ ref_pgmid    = is_reference-ref_pgmid
                                             ref_obj_type = is_reference-ref_obj_type
                                             ref_obj_name = is_reference-ref_obj_name ]-normalized OPTIONAL ).
  ENDMETHOD.

  METHOD yif_trm_xref_repository~is_sap_object.
    rv_result = xsdbool( line_exists( sap_objects[ pgmid    = is_object-pgmid
                                                   obj_type = is_object-obj_type
                                                   obj_name = is_object-obj_name ] ) ).
  ENDMETHOD.

  METHOD yif_trm_xref_repository~method_exists.
    rv_result = xsdbool( NOT line_exists( missing_methods[ class_name  = iv_class_name
                                                           method_name = iv_method_name ] ) ).
  ENDMETHOD.

  METHOD yif_trm_xref_repository~is_abstract_method.
    rv_result = xsdbool( line_exists( abstract_methods[ table_line = iv_method_name ] ) ).
  ENDMETHOD.

ENDCLASS.


CLASS ltd_system DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    INTERFACES yif_trm_xref_system.

    TYPES: BEGIN OF ty_s_object_description,
             object_name TYPE vrsd-objname,
             description TYPE yif_trm_xref_system=>ty_t_description,
           END OF ty_s_object_description.

    TYPES: BEGIN OF ty_s_method_description,
             object_name TYPE string,
             method_name TYPE string,
             description TYPE yif_trm_xref_system=>ty_s_method_description,
           END OF ty_s_method_description.

    TYPES: BEGIN OF ty_s_object,
             pgmid    TYPE pgmid,
             object   TYPE trobjtype,
             obj_name TYPE trobj_name,
           END OF ty_s_object.

    DATA object_descriptions TYPE STANDARD TABLE OF ty_s_object_description WITH EMPTY KEY.
    DATA method_descriptions TYPE STANDARD TABLE OF ty_s_method_description WITH EMPTY KEY.
    DATA comparison          TYPE vrs_compare_item_tab.
    DATA raise_on_compare    TYPE abap_bool.
    DATA existing_objects    TYPE STANDARD TABLE OF ty_s_object WITH EMPTY KEY.

    TYPES: BEGIN OF ty_s_table_description,
             name        TYPE vrsd-objname,
             description TYPE yif_trm_xref_system=>ty_s_table_description,
           END OF ty_s_table_description.

    TYPES: BEGIN OF ty_s_cds_description,
             name        TYPE vrsd-objname,
             description TYPE yif_trm_xref_system=>ty_s_cds_description,
           END OF ty_s_cds_description.

    DATA table_descriptions TYPE STANDARD TABLE OF ty_s_table_description WITH EMPTY KEY.
    DATA cds_descriptions   TYPE STANDARD TABLE OF ty_s_cds_description WITH EMPTY KEY.

ENDCLASS.


CLASS ltd_system IMPLEMENTATION.

  METHOD yif_trm_xref_system~describe.
    TRY.
        rt_description = object_descriptions[ object_name = iv_object_name ]-description.
      CATCH cx_sy_itab_line_not_found.
        RAISE EXCEPTION NEW ycx_trm_cross_reference( ).
    ENDTRY.
  ENDMETHOD.

  METHOD yif_trm_xref_system~describe_method.
    TRY.
        rs_description = method_descriptions[ object_name = iv_object_name
                                              method_name = iv_method_name ]-description.
      CATCH cx_sy_itab_line_not_found.
        RAISE EXCEPTION NEW ycx_trm_cross_reference( ).
    ENDTRY.
  ENDMETHOD.

  METHOD yif_trm_xref_system~describe_class_part.
    RETURN.
  ENDMETHOD.

  METHOD yif_trm_xref_system~describe_table.
    TRY.
        rs_description = table_descriptions[ name = iv_table_name ]-description.
      CATCH cx_sy_itab_line_not_found.
        RAISE EXCEPTION NEW ycx_trm_cross_reference( ).
    ENDTRY.
  ENDMETHOD.

  METHOD yif_trm_xref_system~describe_cds.
    TRY.
        rs_description = cds_descriptions[ name = iv_cds_name ]-description.
      CATCH cx_sy_itab_line_not_found.
        RAISE EXCEPTION NEW ycx_trm_cross_reference( ).
    ENDTRY.
  ENDMETHOD.

  METHOD yif_trm_xref_system~compare_versions.
    IF raise_on_compare = abap_true.
      RAISE EXCEPTION NEW ycx_trm_cross_reference( ).
    ENDIF.

    rt_comparison = comparison.
  ENDMETHOD.

  METHOD yif_trm_xref_system~object_exists.
    rv_result = xsdbool( line_exists( existing_objects[ pgmid    = iv_pgmid
                                                        object   = iv_object
                                                        obj_name = iv_obj_name ] ) ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_run DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    CONSTANTS c_class     TYPE trobj_name VALUE 'ZCL_TRM_TEST'.
    CONSTANTS c_interface TYPE trobj_name VALUE 'ZIF_TRM_TEST'.
    CONSTANTS c_dtel      TYPE trobj_name VALUE 'ZTRM_TEST_DTEL'.
    CONSTANTS c_cds       TYPE trobj_name VALUE 'ZTRM_TEST_CDS'.
    CONSTANTS c_table     TYPE trobj_name VALUE 'ZTRM_TEST_TAB'.

    TYPES ty_t_parameters TYPE yif_trm_xref_system=>ty_s_method_description-parameters.

    DATA cut                TYPE REF TO ycl_trm_cross_ref_analisys.
    DATA repository         TYPE REF TO ltd_repository.
    DATA source_system      TYPE REF TO ltd_system.
    DATA destination_system TYPE REF TO ltd_system.
    DATA program            TYPE cnvcdmccts_objects_set.
    DATA second_program     TYPE cnvcdmccts_objects_set.

    METHODS setup.

    METHODS unsupported_type_not_analyzed  FOR TESTING RAISING cx_static_check.
    METHODS sap_object_not_analyzed        FOR TESTING RAISING cx_static_check.
    METHODS missing_method_not_analyzed    FOR TESTING RAISING cx_static_check.
    METHODS cinc_is_analyzed_as_reps       FOR TESTING RAISING cx_static_check.
    METHODS fragments_are_analyzed         FOR TESTING RAISING cx_static_check.
    METHODS no_objects_raises_019          FOR TESTING RAISING cx_static_check.
    METHODS no_references_returns_initial  FOR TESTING RAISING cx_static_check.
    METHODS prog_and_reps_refs_ignored     FOR TESTING RAISING cx_static_check.
    METHODS refs_grouped_by_referenced_obj FOR TESTING RAISING cx_static_check.
    METHODS clas_removed_from_object_list  FOR TESTING RAISING cx_static_check.
    METHODS subobject_no_pgmid_ignored     FOR TESTING RAISING cx_static_check.
    METHODS normalized_reference_renamed   FOR TESTING RAISING cx_static_check.
    METHODS normalized_meth_merged_deleted FOR TESTING RAISING cx_static_check.
    METHODS sap_reference                  FOR TESTING RAISING cx_static_check.
    METHODS also_in_transport_request      FOR TESTING RAISING cx_static_check.
    METHODS clas_in_request_by_clsd        FOR TESTING RAISING cx_static_check.
    METHODS devc_exists_in_destination     FOR TESTING RAISING cx_static_check.
    METHODS devc_only_in_source            FOR TESTING RAISING cx_static_check.
    METHODS not_comparable_only_in_source  FOR TESTING RAISING cx_static_check.
    METHODS equal_in_destination           FOR TESTING RAISING cx_static_check.
    METHODS different_in_destination       FOR TESTING RAISING cx_static_check.
    METHODS clas_only_in_source_by_clsd    FOR TESTING RAISING cx_static_check.
    METHODS clas_exists_by_clsd            FOR TESTING RAISING cx_static_check.
    METHODS compare_rfc_error_raises       FOR TESTING RAISING cx_static_check.
    METHODS meth_same_signature_exists     FOR TESTING RAISING cx_static_check.
    METHODS meth_param_type_changed_warn   FOR TESTING RAISING cx_static_check.
    METHODS meth_new_mandatory_param_error FOR TESTING RAISING cx_static_check.
    METHODS meth_definition_in_request     FOR TESTING RAISING cx_static_check.
    METHODS meth_definition_missing        FOR TESTING RAISING cx_static_check.
    METHODS meth_implementation_not_in_tr  FOR TESTING RAISING cx_static_check.
    METHODS meth_alias_resolved            FOR TESTING RAISING cx_static_check.
    METHODS meth_alias_missing_in_dest_err FOR TESTING RAISING cx_static_check.
    METHODS meth_new_mandatory_in_src_err  FOR TESTING RAISING cx_static_check.
    METHODS meth_new_optional_in_src_warn  FOR TESTING RAISING cx_static_check.
    METHODS intf_type_changed_warn         FOR TESTING RAISING cx_static_check.
    METHODS intf_type_same_not_relevant    FOR TESTING RAISING cx_static_check.
    METHODS clas_new_atrb_error            FOR TESTING RAISING cx_static_check.
    METHODS clas_atrb_exists_ok            FOR TESTING RAISING cx_static_check.
    METHODS cds_used_field_missing_err     FOR TESTING RAISING cx_static_check.
    METHODS cds_used_fields_exist_not_rel  FOR TESTING RAISING cx_static_check.
    METHODS cds_calculated_field_warn      FOR TESTING RAISING cx_static_check.
    METHODS cds_unknown_element_warn       FOR TESTING RAISING cx_static_check.
    METHODS table_used_field_missing_err   FOR TESTING RAISING cx_static_check.
    METHODS table_field_type_changed_warn  FOR TESTING RAISING cx_static_check.
    METHODS cds_in_request_base_field_err  FOR TESTING RAISING cx_static_check.
    METHODS cds_in_request_base_ok         FOR TESTING RAISING cx_static_check.
    METHODS cds_with_parameters_warn       FOR TESTING RAISING cx_static_check.
    METHODS intf_used_comp_exists_ok       FOR TESTING RAISING cx_static_check.
    METHODS intf_used_comp_missing_error   FOR TESTING RAISING cx_static_check.
    METHODS intf_atrb_field_differs_warn   FOR TESTING RAISING cx_static_check.
    METHODS intf_atrb_missing_error        FOR TESTING RAISING cx_static_check.
    METHODS intf_new_atrb_in_source_error  FOR TESTING RAISING cx_static_check.
    METHODS cpub_methods_exist_irrelevant  FOR TESTING RAISING cx_static_check.
    METHODS cpub_method_missing_error      FOR TESTING RAISING cx_static_check.
    METHODS enqueue_with_enqu_in_request   FOR TESTING RAISING cx_static_check.
    METHODS enqueue_enqu_exists_in_dest    FOR TESTING RAISING cx_static_check.
    METHODS enqueue_enqu_only_in_source    FOR TESTING RAISING cx_static_check.
    METHODS abstract_meth_class_in_request FOR TESTING RAISING cx_static_check.
    METHODS abstract_meth_part_in_request  FOR TESTING RAISING cx_static_check.
    METHODS abstract_meth_not_in_request   FOR TESTING RAISING cx_static_check.
    METHODS not_abstract_meth_unchanged    FOR TESTING RAISING cx_static_check.

    METHODS given_reference_to_enqueue.

    METHODS given_interface_method_ref
      IMPORTING iv_abstract      TYPE abap_bool
      RETURNING VALUE(rv_method) TYPE trobj_name.

    METHODS object
      IMPORTING iv_pgmid         TYPE pgmid
                iv_type          TYPE trobjtype
                iv_name          TYPE csequence
      RETURNING VALUE(rs_object) TYPE cnvcdmccts_objects_set.

    METHODS reference
      IMPORTING is_from             TYPE cnvcdmccts_objects_set
                iv_ref_pgmid        TYPE pgmid
                iv_ref_type         TYPE trobjtype
                iv_ref_name         TYPE csequence
      RETURNING VALUE(rs_reference) TYPE cnvcdmccts_objs_ref.

    METHODS method_name
      IMPORTING iv_class       TYPE csequence
                iv_method      TYPE csequence
      RETURNING VALUE(rv_name) TYPE trobj_name.

    METHODS parameter
      IMPORTING iv_name             TYPE csequence
                iv_type             TYPE csequence
                iv_optional         TYPE abap_bool DEFAULT abap_false
      RETURNING VALUE(rs_parameter) TYPE vseoparam.

    METHODS method_description
      IMPORTING it_parameters         TYPE ty_t_parameters
                iv_defined_in_type    TYPE trobjtype DEFAULT 'CPUB'
      RETURNING VALUE(rs_description) TYPE yif_trm_xref_system=>ty_s_method_description.

    METHODS given_reference_to_dtel.

    METHODS given_method_reference
      IMPORTING iv_method TYPE csequence.

    METHODS given_method_in_systems
      IMPORTING iv_object_name        TYPE csequence
                iv_method_name        TYPE csequence
                is_source_method      TYPE yif_trm_xref_system=>ty_s_method_description OPTIONAL
                is_destination_method TYPE yif_trm_xref_system=>ty_s_method_description OPTIONAL
                iv_in_source          TYPE abap_bool DEFAULT abap_true
                iv_in_destination     TYPE abap_bool DEFAULT abap_true.

    METHODS given_interface_usage
      IMPORTING iv_component_type TYPE trobjtype
                iv_component_name TYPE csequence.

    METHODS given_class_part_usage.

    METHODS given_interface_type_usage
      IMPORTING iv_source_type      TYPE string
                iv_destination_type TYPE string.

    METHODS given_class_attribute_usage
      IMPORTING iv_attribute             TYPE csequence
                iv_destination_attribute TYPE csequence.

    METHODS given_cds_usage
      IMPORTING iv_used_component TYPE csequence.

    METHODS given_table_usage
      IMPORTING iv_used_field TYPE csequence.

    METHODS given_cds_in_request
      IMPORTING iv_destination_has_field TYPE abap_bool
      RETURNING VALUE(rs_cds)            TYPE cnvcdmccts_objects_set.

    METHODS cds_field
      IMPORTING iv_element           TYPE csequence
                iv_base_field        TYPE csequence OPTIONAL
                iv_calculated        TYPE abap_bool DEFAULT abap_false
      RETURNING VALUE(rs_field)      TYPE ytrm_s_ddl_base_fields.

    METHODS table_field
      IMPORTING iv_name         TYPE csequence
                iv_length       TYPE i DEFAULT 10
      RETURNING VALUE(rs_field) TYPE dd03v.

    METHODS run
      IMPORTING it_objects         TYPE ycl_trm_cross_ref_analisys=>ty_t_objects
      RETURNING VALUE(rs_analysis) TYPE ycl_trm_cross_ref_analisys=>ty_s_return
      RAISING   ycx_trm_cross_reference.

    METHODS has_result
      IMPORTING is_analysis      TYPE ycl_trm_cross_ref_analisys=>ty_s_return
                iv_type          TYPE trobjtype
                iv_name          TYPE csequence
      RETURNING VALUE(rv_result) TYPE abap_bool.

    METHODS result_of
      IMPORTING is_analysis      TYPE ycl_trm_cross_ref_analisys=>ty_s_return
                iv_type          TYPE trobjtype
                iv_name          TYPE csequence
      RETURNING VALUE(rs_result) TYPE yif_trm_cross_reference=>ty_s_result.

    METHODS status_of
      IMPORTING is_analysis      TYPE ycl_trm_cross_ref_analisys=>ty_s_return
                iv_type          TYPE trobjtype
                iv_name          TYPE csequence
      RETURNING VALUE(rv_status) TYPE yif_trm_cross_reference=>ty_e_status.

ENDCLASS.


CLASS ltc_run IMPLEMENTATION.

  METHOD setup.
    repository         = NEW #( ).
    source_system      = NEW #( ).
    destination_system = NEW #( ).

    cut = NEW #( iv_rfc_comparison     = 'TEST'
                 io_repository         = repository
                 io_source_system      = source_system
                 io_destination_system = destination_system ).

    program        = object( iv_pgmid = 'R3TR' iv_type = 'PROG' iv_name = 'ZTRM_TEST_PROGRAM' ).
    second_program = object( iv_pgmid = 'R3TR' iv_type = 'PROG' iv_name = 'ZTRM_TEST_PROGRAM_2' ).
  ENDMETHOD.

  METHOD unsupported_type_not_analyzed.
    given_reference_to_dtel( ).
    DATA(ls_unsupported) = object( iv_pgmid = 'R3TR' iv_type = 'XXXX' iv_name = 'ZTRM_TEST_OBJECT' ).

    DATA(ls_analysis) = run( VALUE #( ( program ) ( ls_unsupported ) ) ).

    cl_abap_unit_assert=>assert_table_contains(
        line  = ls_unsupported
        table = ls_analysis-analized_objets_resume-not_analyzed_objects ).
  ENDMETHOD.

  METHOD sap_object_not_analyzed.
    given_reference_to_dtel( ).
    DATA(ls_sap_program) = object( iv_pgmid = 'R3TR' iv_type = 'PROG' iv_name = 'SAPMV45A' ).
    repository->sap_objects = VALUE #( ( ls_sap_program ) ).

    DATA(ls_analysis) = run( VALUE #( ( program ) ( ls_sap_program ) ) ).

    cl_abap_unit_assert=>assert_table_contains(
        line  = ls_sap_program
        table = ls_analysis-analized_objets_resume-not_analyzed_objects ).
  ENDMETHOD.

  METHOD missing_method_not_analyzed.
    given_reference_to_dtel( ).
    DATA(ls_method) = object( iv_pgmid = 'LIMU'
                              iv_type  = 'METH'
                              iv_name  = method_name( iv_class = c_class iv_method = 'DO_IT' ) ).
    repository->missing_methods = VALUE #( ( class_name = c_class method_name = 'DO_IT' ) ).

    DATA(ls_analysis) = run( VALUE #( ( program ) ( ls_method ) ) ).

    cl_abap_unit_assert=>assert_table_contains(
        line  = ls_method
        table = ls_analysis-analized_objets_resume-not_analyzed_objects ).
  ENDMETHOD.

  METHOD cinc_is_analyzed_as_reps.
    given_reference_to_dtel( ).
    DATA(ls_include) = object( iv_pgmid = 'LIMU' iv_type = 'CINC' iv_name = 'ZCL_TRM_TEST==================CCAU' ).

    DATA(ls_analysis) = run( VALUE #( ( program ) ( ls_include ) ) ).

    cl_abap_unit_assert=>assert_table_contains(
        line  = object( iv_pgmid = 'LIMU' iv_type = 'REPS' iv_name = ls_include-obj_name )
        table = ls_analysis-analized_objets_resume-analyzed_objects ).
  ENDMETHOD.

  METHOD fragments_are_analyzed.
    given_reference_to_dtel( ).
    DATA(ls_fragment) = object( iv_pgmid = 'LIMU' iv_type = 'CPUB' iv_name = c_class ).
    repository->fragments = VALUE #( ( ls_fragment ) ).

    DATA(ls_analysis) = run( VALUE #( ( program ) ) ).

    cl_abap_unit_assert=>assert_table_contains( line  = ls_fragment
                                                table = ls_analysis-analized_objets_resume-analyzed_objects ).
  ENDMETHOD.

  METHOD no_objects_raises_019.
    TRY.
        run( VALUE #( ( object( iv_pgmid = 'R3TR' iv_type = 'XXXX' iv_name = 'ZTRM_TEST_OBJECT' ) ) ) ).
        cl_abap_unit_assert=>fail( 'Exception expected' ).
      CATCH ycx_trm_cross_reference INTO DATA(lx_error).
        DATA(lt_messages) = lx_error->logger->get_messages_table( ).
        cl_abap_unit_assert=>assert_true( xsdbool( line_exists( lt_messages[ msgid = 'YTRM' msgno = '019' ] ) ) ).
    ENDTRY.
  ENDMETHOD.

  METHOD no_references_returns_initial.
    DATA(ls_analysis) = run( VALUE #( ( program ) ) ).

    cl_abap_unit_assert=>assert_initial( ls_analysis ).
  ENDMETHOD.

  METHOD prog_and_reps_refs_ignored.
    repository->references = VALUE #(
        ( reference( is_from = program iv_ref_pgmid = 'R3TR' iv_ref_type = 'PROG' iv_ref_name = 'ZTRM_OTHER_PROGRAM' ) )
        ( reference( is_from = program iv_ref_pgmid = 'LIMU' iv_ref_type = 'REPS' iv_ref_name = 'ZTRM_OTHER_INCLUDE' ) )
        ( reference( is_from = program iv_ref_pgmid = 'R3TR' iv_ref_type = 'DTEL' iv_ref_name = c_dtel ) ) ).

    DATA(ls_analysis) = run( VALUE #( ( program ) ) ).

    cl_abap_unit_assert=>assert_true( has_result( is_analysis = ls_analysis iv_type = 'DTEL' iv_name = c_dtel ) ).
    cl_abap_unit_assert=>assert_false(
        has_result( is_analysis = ls_analysis iv_type = 'PROG' iv_name = 'ZTRM_OTHER_PROGRAM' ) ).
    cl_abap_unit_assert=>assert_false(
        has_result( is_analysis = ls_analysis iv_type = 'REPS' iv_name = 'ZTRM_OTHER_INCLUDE' ) ).
  ENDMETHOD.

  METHOD refs_grouped_by_referenced_obj.
    repository->references = VALUE #(
        ( reference( is_from = program        iv_ref_pgmid = 'R3TR' iv_ref_type = 'DTEL' iv_ref_name = c_dtel ) )
        ( reference( is_from = second_program iv_ref_pgmid = 'R3TR' iv_ref_type = 'DTEL' iv_ref_name = c_dtel ) ) ).

    DATA(ls_analysis) = run( VALUE #( ( program ) ( second_program ) ) ).

    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lines( ls_analysis-result ) ).
    cl_abap_unit_assert=>assert_equals(
        exp = 2
        act = lines( result_of( is_analysis = ls_analysis iv_type = 'DTEL' iv_name = c_dtel )-object_list ) ).
  ENDMETHOD.

  METHOD clas_removed_from_object_list.
    DATA(ls_class) = object( iv_pgmid = 'R3TR' iv_type = 'CLAS' iv_name = 'ZCL_TRM_TEST_USER' ).
    repository->references = VALUE #(
        ( reference( is_from = ls_class iv_ref_pgmid = 'R3TR' iv_ref_type = 'DTEL' iv_ref_name = c_dtel ) )
        ( reference( is_from = program  iv_ref_pgmid = 'R3TR' iv_ref_type = 'DTEL' iv_ref_name = c_dtel ) ) ).

    DATA(ls_analysis) = run( VALUE #( ( program ) ( ls_class ) ) ).

    DATA(lt_object_list) = result_of( is_analysis = ls_analysis iv_type = 'DTEL' iv_name = c_dtel )-object_list.
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lines( lt_object_list ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'PROG'
                                        act = lt_object_list[ 1 ]-type ).
  ENDMETHOD.

  METHOD subobject_no_pgmid_ignored.
    repository->types_without_pgmid = VALUE #( ( 'ATRB' ) ).
    repository->references = VALUE #(
        ( reference( is_from = program iv_ref_pgmid = 'LIMU' iv_ref_type = 'ATRB' iv_ref_name = 'ZTRM_TEST_ATTRIBUTE' ) )
        ( reference( is_from = program iv_ref_pgmid = 'R3TR' iv_ref_type = 'DTEL' iv_ref_name = c_dtel ) ) ).

    DATA(ls_analysis) = run( VALUE #( ( program ) ) ).

    cl_abap_unit_assert=>assert_false(
        has_result( is_analysis = ls_analysis iv_type = 'ATRB' iv_name = 'ZTRM_TEST_ATTRIBUTE' ) ).
  ENDMETHOD.

  METHOD normalized_reference_renamed.
    repository->references = VALUE #(
        ( reference( is_from = program iv_ref_pgmid = 'R3TR' iv_ref_type = 'DTEL' iv_ref_name = 'ZTRM_TEST_OLD' ) ) ).
    repository->normalizations = VALUE #(
        ( ref_pgmid    = 'R3TR'
          ref_obj_type = 'DTEL'
          ref_obj_name = 'ZTRM_TEST_OLD'
          normalized   = VALUE #( ( ref_pgmid = 'R3TR' ref_obj_type = 'DTEL' ref_obj_name = 'ZTRM_TEST_NEW' ) ) ) ).

    DATA(ls_analysis) = run( VALUE #( ( program ) ) ).

    cl_abap_unit_assert=>assert_true( has_result( is_analysis = ls_analysis iv_type = 'DTEL' iv_name = 'ZTRM_TEST_NEW' ) ).
    cl_abap_unit_assert=>assert_false( has_result( is_analysis = ls_analysis iv_type = 'DTEL' iv_name = 'ZTRM_TEST_OLD' ) ).
  ENDMETHOD.

  METHOD normalized_meth_merged_deleted.
    DATA(lv_method) = method_name( iv_class = c_class iv_method = 'DO_IT' ).
    repository->references = VALUE #(
        ( reference( is_from = program        iv_ref_pgmid = 'LIMU' iv_ref_type = 'METH' iv_ref_name = lv_method ) )
        ( reference( is_from = second_program iv_ref_pgmid = 'R3TR' iv_ref_type = 'INTF' iv_ref_name = c_interface ) ) ).
    repository->normalizations = VALUE #(
        ( ref_pgmid    = 'LIMU'
          ref_obj_type = 'METH'
          ref_obj_name = lv_method
          normalized   = VALUE #( ( ref_pgmid = 'R3TR' ref_obj_type = 'INTF' ref_obj_name = c_interface ) ) ) ).

    DATA(ls_analysis) = run( VALUE #( ( program ) ( second_program ) ) ).

    cl_abap_unit_assert=>assert_false( has_result( is_analysis = ls_analysis iv_type = 'METH' iv_name = lv_method ) ).
    cl_abap_unit_assert=>assert_equals(
        exp = 2
        act = lines( result_of( is_analysis = ls_analysis iv_type = 'INTF' iv_name = c_interface )-object_list ) ).
  ENDMETHOD.

  METHOD sap_reference.
    repository->references = VALUE #(
        ( reference( is_from = program iv_ref_pgmid = 'R3TR' iv_ref_type = 'DTEL' iv_ref_name = 'MATNR' ) ) ).
    repository->sap_objects = VALUE #( ( object( iv_pgmid = 'R3TR' iv_type = 'DTEL' iv_name = 'MATNR' ) ) ).

    DATA(ls_analysis) = run( VALUE #( ( program ) ) ).

    cl_abap_unit_assert=>assert_equals( exp = yif_trm_cross_reference=>c_status-sap_reference
                                        act = status_of( is_analysis = ls_analysis iv_type = 'DTEL' iv_name = 'MATNR' ) ).
  ENDMETHOD.

  METHOD also_in_transport_request.
    given_reference_to_dtel( ).

    DATA(ls_analysis) = run( VALUE #( ( program )
                                      ( object( iv_pgmid = 'R3TR' iv_type = 'DTEL' iv_name = c_dtel ) ) ) ).

    cl_abap_unit_assert=>assert_equals( exp = yif_trm_cross_reference=>c_status-also_in_transport_request
                                        act = status_of( is_analysis = ls_analysis iv_type = 'DTEL' iv_name = c_dtel ) ).
  ENDMETHOD.

  METHOD clas_in_request_by_clsd.
    repository->references = VALUE #(
        ( reference( is_from = program iv_ref_pgmid = 'R3TR' iv_ref_type = 'CLAS' iv_ref_name = c_class ) ) ).

    DATA(ls_analysis) = run( VALUE #( ( program )
                                      ( object( iv_pgmid = 'LIMU' iv_type = 'CLSD' iv_name = c_class ) ) ) ).

    cl_abap_unit_assert=>assert_equals( exp = yif_trm_cross_reference=>c_status-also_in_transport_request
                                        act = status_of( is_analysis = ls_analysis iv_type = 'CLAS' iv_name = c_class ) ).
  ENDMETHOD.

  METHOD devc_exists_in_destination.
    repository->references = VALUE #(
        ( reference( is_from = program iv_ref_pgmid = 'R3TR' iv_ref_type = 'DEVC' iv_ref_name = 'ZTRM_TEST_PACKAGE' ) ) ).
    destination_system->existing_objects = VALUE #( ( pgmid = 'R3TR' object = 'DEVC' obj_name = 'ZTRM_TEST_PACKAGE' ) ).

    DATA(ls_analysis) = run( VALUE #( ( program ) ) ).

    cl_abap_unit_assert=>assert_equals(
        exp = yif_trm_cross_reference=>c_status-exist_in_destination
        act = status_of( is_analysis = ls_analysis iv_type = 'DEVC' iv_name = 'ZTRM_TEST_PACKAGE' ) ).
  ENDMETHOD.

  METHOD devc_only_in_source.
    repository->references = VALUE #(
        ( reference( is_from = program iv_ref_pgmid = 'R3TR' iv_ref_type = 'DEVC' iv_ref_name = 'ZTRM_TEST_PACKAGE' ) ) ).

    DATA(ls_analysis) = run( VALUE #( ( program ) ) ).

    cl_abap_unit_assert=>assert_equals(
        exp = yif_trm_cross_reference=>c_status-only_in_source
        act = status_of( is_analysis = ls_analysis iv_type = 'DEVC' iv_name = 'ZTRM_TEST_PACKAGE' ) ).
  ENDMETHOD.

  METHOD not_comparable_only_in_source.
    given_reference_to_dtel( ).
    destination_system->comparison = VALUE #(
        ( fragid = 'R3TR' fragment = 'DTEL' fragname = c_dtel not_comparable = abap_true ) ).

    DATA(ls_analysis) = run( VALUE #( ( program ) ) ).

    cl_abap_unit_assert=>assert_equals( exp = yif_trm_cross_reference=>c_status-only_in_source
                                        act = status_of( is_analysis = ls_analysis iv_type = 'DTEL' iv_name = c_dtel ) ).
  ENDMETHOD.

  METHOD equal_in_destination.
    given_reference_to_dtel( ).
    destination_system->comparison = VALUE #( ( fragid = 'R3TR' fragment = 'DTEL' fragname = c_dtel equal = abap_true ) ).

    DATA(ls_analysis) = run( VALUE #( ( program ) ) ).

    cl_abap_unit_assert=>assert_equals( exp = yif_trm_cross_reference=>c_status-equal_in_destination
                                        act = status_of( is_analysis = ls_analysis iv_type = 'DTEL' iv_name = c_dtel ) ).
  ENDMETHOD.

  METHOD different_in_destination.
    given_reference_to_dtel( ).

    DATA(ls_analysis) = run( VALUE #( ( program ) ) ).

    cl_abap_unit_assert=>assert_equals( exp = yif_trm_cross_reference=>c_status-different_in_destination
                                        act = status_of( is_analysis = ls_analysis iv_type = 'DTEL' iv_name = c_dtel ) ).
  ENDMETHOD.

  METHOD clas_only_in_source_by_clsd.
    repository->references = VALUE #(
        ( reference( is_from = program iv_ref_pgmid = 'R3TR' iv_ref_type = 'CLAS' iv_ref_name = c_class ) ) ).
    destination_system->comparison = VALUE #(
        ( fragid = 'LIMU' fragment = 'CLSD' fragname = c_class not_comparable = abap_true ) ).

    DATA(ls_analysis) = run( VALUE #( ( program ) ) ).

    cl_abap_unit_assert=>assert_equals( exp = yif_trm_cross_reference=>c_status-only_in_source
                                        act = status_of( is_analysis = ls_analysis iv_type = 'CLAS' iv_name = c_class ) ).
  ENDMETHOD.

  METHOD clas_exists_by_clsd.
    repository->references = VALUE #(
        ( reference( is_from = program iv_ref_pgmid = 'R3TR' iv_ref_type = 'CLAS' iv_ref_name = c_class ) ) ).
    destination_system->comparison = VALUE #( ( fragid = 'LIMU' fragment = 'CLSD' fragname = c_class equal = abap_true ) ).

    DATA(ls_analysis) = run( VALUE #( ( program ) ) ).

    cl_abap_unit_assert=>assert_equals( exp = yif_trm_cross_reference=>c_status-exist_in_destination
                                        act = status_of( is_analysis = ls_analysis iv_type = 'CLAS' iv_name = c_class ) ).
  ENDMETHOD.

  METHOD compare_rfc_error_raises.
    given_reference_to_dtel( ).
    destination_system->raise_on_compare = abap_true.

    TRY.
        run( VALUE #( ( program ) ) ).
        cl_abap_unit_assert=>fail( 'Exception expected' ).
      CATCH ycx_trm_cross_reference INTO DATA(lx_error).
        cl_abap_unit_assert=>assert_bound( lx_error ).
    ENDTRY.
  ENDMETHOD.

  METHOD meth_same_signature_exists.
    given_method_reference( 'DO_IT' ).
    DATA(ls_method) = method_description( VALUE #( ( parameter( iv_name = 'IV_A' iv_type = 'STRING' ) ) ) ).
    given_method_in_systems( iv_object_name        = c_class
                             iv_method_name        = 'DO_IT'
                             is_source_method      = ls_method
                             is_destination_method = ls_method ).

    DATA(ls_analysis) = run( VALUE #( ( program ) ) ).

    cl_abap_unit_assert=>assert_equals(
        exp = yif_trm_cross_reference=>c_status-exist_in_destination
        act = status_of( is_analysis = ls_analysis
                         iv_type     = 'METH'
                         iv_name     = method_name( iv_class = c_class iv_method = 'DO_IT' ) ) ).
  ENDMETHOD.

  METHOD meth_param_type_changed_warn.
    given_method_reference( 'DO_IT' ).
    given_method_in_systems(
        iv_object_name        = c_class
        iv_method_name        = 'DO_IT'
        is_source_method      = method_description( VALUE #( ( parameter( iv_name = 'IV_A' iv_type = 'STRING' ) ) ) )
        is_destination_method = method_description( VALUE #( ( parameter( iv_name = 'IV_A' iv_type = 'I' ) ) ) ) ).

    DATA(ls_analysis) = run( VALUE #( ( program ) ) ).

    cl_abap_unit_assert=>assert_equals(
        exp = yif_trm_cross_reference=>c_status-method_definition_dif_in_dest
        act = status_of( is_analysis = ls_analysis
                         iv_type     = 'METH'
                         iv_name     = method_name( iv_class = c_class iv_method = 'DO_IT' ) ) ).
  ENDMETHOD.

  METHOD meth_new_mandatory_param_error.
    given_method_reference( 'DO_IT' ).
    given_method_in_systems(
        iv_object_name        = c_class
        iv_method_name        = 'DO_IT'
        is_source_method      = method_description( VALUE #( ( parameter( iv_name = 'IV_A' iv_type = 'STRING' ) ) ) )
        is_destination_method = method_description( VALUE #( ( parameter( iv_name = 'IV_A' iv_type = 'STRING' ) )
                                                             ( parameter( iv_name = 'IV_B' iv_type = 'STRING' ) ) ) ) ).

    DATA(ls_analysis) = run( VALUE #( ( program ) ) ).

    cl_abap_unit_assert=>assert_equals(
        exp = yif_trm_cross_reference=>c_status-method_def_dif_in_dest_w_err
        act = status_of( is_analysis = ls_analysis
                         iv_type     = 'METH'
                         iv_name     = method_name( iv_class = c_class iv_method = 'DO_IT' ) ) ).
  ENDMETHOD.

  METHOD meth_definition_in_request.
    given_method_reference( 'DO_IT' ).
    DATA(ls_method) = method_description( VALUE #( ( parameter( iv_name = 'IV_A' iv_type = 'STRING' ) ) ) ).
    given_method_in_systems( iv_object_name        = c_class
                             iv_method_name        = 'DO_IT'
                             is_source_method      = ls_method
                             is_destination_method = ls_method ).

    DATA(ls_analysis) = run( VALUE #( ( program )
                                      ( object( iv_pgmid = 'LIMU' iv_type = 'CPUB' iv_name = c_class ) ) ) ).

    cl_abap_unit_assert=>assert_equals(
        exp = yif_trm_cross_reference=>c_status-definition_also_in_trans_req
        act = status_of( is_analysis = ls_analysis
                         iv_type     = 'METH'
                         iv_name     = method_name( iv_class = c_class iv_method = 'DO_IT' ) ) ).
  ENDMETHOD.

  METHOD meth_definition_missing.
    given_method_reference( 'DO_IT' ).
    given_method_in_systems(
        iv_object_name    = c_class
        iv_method_name    = 'DO_IT'
        is_source_method  = method_description( it_parameters      = VALUE #( )
                                                iv_defined_in_type = 'CLAS' )
        iv_in_destination = abap_false ).

    DATA(ls_analysis) = run( VALUE #( ( program ) ) ).

    cl_abap_unit_assert=>assert_equals(
        exp = yif_trm_cross_reference=>c_status-definition_missing
        act = status_of( is_analysis = ls_analysis
                         iv_type     = 'METH'
                         iv_name     = method_name( iv_class = c_class iv_method = 'DO_IT' ) ) ).
  ENDMETHOD.

  METHOD meth_implementation_not_in_tr.
    given_method_reference( 'DO_IT' ).
    given_method_in_systems( iv_object_name     = c_class
                             iv_method_name     = 'DO_IT'
                             is_source_method   = method_description( VALUE #( ) )
                             iv_in_destination  = abap_false ).

    DATA(ls_analysis) = run( VALUE #( ( program ) ) ).

    cl_abap_unit_assert=>assert_equals(
        exp = yif_trm_cross_reference=>c_status-only_in_source
        act = status_of( is_analysis = ls_analysis
                         iv_type     = 'METH'
                         iv_name     = method_name( iv_class = c_class iv_method = 'DO_IT' ) ) ).
  ENDMETHOD.

  METHOD meth_alias_resolved.
    given_method_reference( 'ALIAS_X' ).
    source_system->object_descriptions = VALUE #(
        ( object_name = c_class
          description = VALUE #( ( sub_object_type       = 'METH'
                                   sub_object_name       = |{ c_interface }~DO_IT|
                                   sub_object_name_alias = 'ALIAS_X' ) ) ) ).
    destination_system->object_descriptions = source_system->object_descriptions.
    DATA(ls_method) = method_description( VALUE #( ( parameter( iv_name = 'IV_A' iv_type = 'STRING' ) ) ) ).
    given_method_in_systems( iv_object_name        = c_interface
                             iv_method_name        = 'DO_IT'
                             is_source_method      = ls_method
                             is_destination_method = ls_method ).

    DATA(ls_analysis) = run( VALUE #( ( program ) ) ).

    " The reference is returned with the real name of the method, not the alias
    cl_abap_unit_assert=>assert_equals(
        exp = yif_trm_cross_reference=>c_status-exist_in_destination
        act = status_of( is_analysis = ls_analysis
                         iv_type     = 'METH'
                         iv_name     = method_name( iv_class = c_class iv_method = |{ c_interface }~DO_IT| ) ) ).
  ENDMETHOD.

  METHOD meth_alias_missing_in_dest_err.
    given_method_reference( 'ALIAS_X' ).
    source_system->object_descriptions = VALUE #(
        ( object_name = c_class
          description = VALUE #( ( sub_object_type       = 'METH'
                                   sub_object_name       = |{ c_interface }~DO_IT|
                                   sub_object_name_alias = 'ALIAS_X' ) ) ) ).
    destination_system->object_descriptions = VALUE #(
        ( object_name = c_class
          description = VALUE #( ( sub_object_type = 'METH' sub_object_name = |{ c_interface }~DO_IT| ) ) ) ).
    DATA(ls_method) = method_description( VALUE #( ( parameter( iv_name = 'IV_A' iv_type = 'STRING' ) ) ) ).
    given_method_in_systems( iv_object_name        = c_interface
                             iv_method_name        = 'DO_IT'
                             is_source_method      = ls_method
                             is_destination_method = ls_method ).

    DATA(ls_analysis) = run( VALUE #( ( program ) ) ).

    cl_abap_unit_assert=>assert_equals(
        exp = yif_trm_cross_reference=>c_status-only_in_source
        act = status_of( is_analysis = ls_analysis
                         iv_type     = 'METH'
                         iv_name     = method_name( iv_class = c_class iv_method = |{ c_interface }~DO_IT| ) ) ).
  ENDMETHOD.

  METHOD meth_new_mandatory_in_src_err.
    given_method_reference( 'DO_IT' ).
    given_method_in_systems(
        iv_object_name        = c_class
        iv_method_name        = 'DO_IT'
        is_source_method      = method_description( VALUE #( ( parameter( iv_name = 'IV_A' iv_type = 'STRING' ) )
                                                             ( parameter( iv_name = 'IV_B' iv_type = 'STRING' ) ) ) )
        is_destination_method = method_description( VALUE #( ( parameter( iv_name = 'IV_A' iv_type = 'STRING' ) ) ) ) ).

    DATA(ls_analysis) = run( VALUE #( ( program ) ) ).

    cl_abap_unit_assert=>assert_equals(
        exp = yif_trm_cross_reference=>c_status-method_def_dif_in_dest_w_err
        act = status_of( is_analysis = ls_analysis
                         iv_type     = 'METH'
                         iv_name     = method_name( iv_class = c_class iv_method = 'DO_IT' ) ) ).
  ENDMETHOD.

  METHOD meth_new_optional_in_src_warn.
    given_method_reference( 'DO_IT' ).
    given_method_in_systems(
        iv_object_name        = c_class
        iv_method_name        = 'DO_IT'
        is_source_method      = method_description(
                                    VALUE #( ( parameter( iv_name = 'IV_A' iv_type = 'STRING' ) )
                                             ( parameter( iv_name = 'IV_B' iv_type = 'STRING' iv_optional = abap_true ) ) ) )
        is_destination_method = method_description( VALUE #( ( parameter( iv_name = 'IV_A' iv_type = 'STRING' ) ) ) ) ).

    DATA(ls_analysis) = run( VALUE #( ( program ) ) ).

    cl_abap_unit_assert=>assert_equals(
        exp = yif_trm_cross_reference=>c_status-method_definition_dif_in_dest
        act = status_of( is_analysis = ls_analysis
                         iv_type     = 'METH'
                         iv_name     = method_name( iv_class = c_class iv_method = 'DO_IT' ) ) ).
  ENDMETHOD.

  METHOD intf_type_changed_warn.
    given_interface_type_usage( iv_source_type      = `x TYPE i, y TYPE i, z TYPE i`
                                iv_destination_type = `x TYPE i, y TYPE i` ).

    DATA(ls_analysis) = run( VALUE #( ( program ) ) ).

    DATA(ls_result) = result_of( is_analysis = ls_analysis iv_type = 'INTF' iv_name = c_interface ).
    cl_abap_unit_assert=>assert_equals( exp = yif_trm_cross_reference=>c_status-different_in_destination
                                        act = ls_result-status ).
    cl_abap_unit_assert=>assert_equals( exp = icon_led_yellow
                                        act = ls_result-object_list[ 1 ]-severity ).
  ENDMETHOD.

  METHOD intf_type_same_not_relevant.
    given_interface_type_usage( iv_source_type      = `x TYPE i, y TYPE i`
                                iv_destination_type = `x TYPE i, y TYPE i` ).

    DATA(ls_analysis) = run( VALUE #( ( program ) ) ).

    cl_abap_unit_assert=>assert_equals(
        exp = yif_trm_cross_reference=>c_status-different_but_not_relevant
        act = status_of( is_analysis = ls_analysis iv_type = 'INTF' iv_name = c_interface ) ).
  ENDMETHOD.

  METHOD clas_new_atrb_error.
    given_class_attribute_usage( iv_attribute             = 'C_NEW'
                                 iv_destination_attribute = 'C_OLD' ).

    DATA(ls_analysis) = run( VALUE #( ( program ) ) ).

    DATA(ls_result) = result_of( is_analysis = ls_analysis iv_type = 'CLAS' iv_name = c_class ).
    cl_abap_unit_assert=>assert_equals( exp = yif_trm_cross_reference=>c_status-different
                                        act = ls_result-status ).
    cl_abap_unit_assert=>assert_equals( exp = icon_led_red
                                        act = ls_result-object_list[ 1 ]-severity ).
  ENDMETHOD.

  METHOD clas_atrb_exists_ok.
    given_class_attribute_usage( iv_attribute             = 'C_NEW'
                                 iv_destination_attribute = 'C_NEW' ).

    DATA(ls_analysis) = run( VALUE #( ( program ) ) ).

    cl_abap_unit_assert=>assert_equals(
        exp = yif_trm_cross_reference=>c_status-exist_in_destination
        act = status_of( is_analysis = ls_analysis iv_type = 'CLAS' iv_name = c_class ) ).
  ENDMETHOD.

  METHOD cds_used_field_missing_err.
    given_cds_usage( 'NEWFIELD' ).

    DATA(ls_result) = result_of( is_analysis = run( VALUE #( ( program ) ) ) iv_type = 'DDLS' iv_name = c_cds ).

    cl_abap_unit_assert=>assert_equals( exp = yif_trm_cross_reference=>c_status-different
                                        act = ls_result-status ).
    cl_abap_unit_assert=>assert_equals( exp = icon_led_red
                                        act = ls_result-object_list[ 1 ]-severity ).
  ENDMETHOD.

  METHOD cds_used_fields_exist_not_rel.
    given_cds_usage( 'ITEMID' ).

    cl_abap_unit_assert=>assert_equals(
        exp = yif_trm_cross_reference=>c_status-different_but_not_relevant
        act = status_of( is_analysis = run( VALUE #( ( program ) ) ) iv_type = 'DDLS' iv_name = c_cds ) ).
  ENDMETHOD.

  METHOD cds_calculated_field_warn.
    given_cds_usage( 'CALC' ).

    DATA(ls_result) = result_of( is_analysis = run( VALUE #( ( program ) ) ) iv_type = 'DDLS' iv_name = c_cds ).

    cl_abap_unit_assert=>assert_equals( exp = yif_trm_cross_reference=>c_status-different_in_destination
                                        act = ls_result-status ).
    cl_abap_unit_assert=>assert_equals( exp = icon_led_yellow
                                        act = ls_result-object_list[ 1 ]-severity ).
  ENDMETHOD.

  METHOD cds_unknown_element_warn.
    given_cds_usage( '_ASSOC' ).

    DATA(ls_result) = result_of( is_analysis = run( VALUE #( ( program ) ) ) iv_type = 'DDLS' iv_name = c_cds ).

    cl_abap_unit_assert=>assert_equals( exp = yif_trm_cross_reference=>c_status-different_in_destination
                                        act = ls_result-status ).
    cl_abap_unit_assert=>assert_equals( exp = icon_led_yellow
                                        act = ls_result-object_list[ 1 ]-severity ).
  ENDMETHOD.

  METHOD table_used_field_missing_err.
    given_table_usage( 'NEW_FIELD' ).

    DATA(ls_result) = result_of( is_analysis = run( VALUE #( ( program ) ) ) iv_type = 'TABL' iv_name = c_table ).

    cl_abap_unit_assert=>assert_equals( exp = yif_trm_cross_reference=>c_status-different
                                        act = ls_result-status ).
    cl_abap_unit_assert=>assert_equals( exp = icon_led_red
                                        act = ls_result-object_list[ 1 ]-severity ).
  ENDMETHOD.

  METHOD table_field_type_changed_warn.
    given_table_usage( 'AMOUNT' ).

    DATA(ls_result) = result_of( is_analysis = run( VALUE #( ( program ) ) ) iv_type = 'TABL' iv_name = c_table ).

    cl_abap_unit_assert=>assert_equals( exp = yif_trm_cross_reference=>c_status-different_in_destination
                                        act = ls_result-status ).
    cl_abap_unit_assert=>assert_equals( exp = icon_led_yellow
                                        act = ls_result-object_list[ 1 ]-severity ).
  ENDMETHOD.

  METHOD cds_in_request_base_field_err.
    DATA(ls_wide) = given_cds_in_request( iv_destination_has_field = abap_false ).

    DATA(ls_result) = result_of( is_analysis = run( VALUE #( ( ls_wide ) ) ) iv_type = 'DDLS' iv_name = c_cds ).

    cl_abap_unit_assert=>assert_equals( exp = yif_trm_cross_reference=>c_status-different
                                        act = ls_result-status ).
    cl_abap_unit_assert=>assert_equals( exp = icon_led_red
                                        act = ls_result-object_list[ name = ls_wide-obj_name ]-severity ).
  ENDMETHOD.

  METHOD cds_in_request_base_ok.
    DATA(ls_wide) = given_cds_in_request( iv_destination_has_field = abap_true ).

    cl_abap_unit_assert=>assert_equals(
        exp = yif_trm_cross_reference=>c_status-different_in_destination
        act = status_of( is_analysis = run( VALUE #( ( ls_wide ) ) ) iv_type = 'DDLS' iv_name = c_cds ) ).
  ENDMETHOD.

  METHOD cds_with_parameters_warn.
    given_cds_usage( 'ITEMID' ).
    repository->cds_with_parameters = VALUE #( ( c_cds ) ).

    DATA(ls_result) = result_of( is_analysis = run( VALUE #( ( program ) ) ) iv_type = 'DDLS' iv_name = c_cds ).

    cl_abap_unit_assert=>assert_equals( exp = yif_trm_cross_reference=>c_status-different_in_destination
                                        act = ls_result-status ).
    cl_abap_unit_assert=>assert_equals( exp = icon_led_yellow
                                        act = ls_result-object_list[ 1 ]-severity ).
  ENDMETHOD.

  METHOD given_cds_usage.
    repository->references = VALUE #(
        ( reference( is_from = program iv_ref_pgmid = 'R3TR' iv_ref_type = 'DDLS' iv_ref_name = c_cds ) ) ).
    repository->used_components = VALUE #(
        ( reference( is_from      = program
                     iv_ref_pgmid = ''
                     iv_ref_type  = yif_trm_xref_repository=>c_used_component
                     iv_ref_name  = |{ c_cds }~{ iv_used_component }| ) ) ).
    source_system->cds_descriptions = VALUE #(
        ( name        = c_cds
          description = VALUE #( fields = VALUE #( ( cds_field( iv_element = 'ItemId' iv_base_field = 'ITEM_ID' ) )
                                                   ( cds_field( iv_element = 'NewField' iv_base_field = 'NEW_FIELD' ) )
                                                   ( cds_field( iv_element = 'Calc' iv_calculated = abap_true ) ) ) ) ) ).
    destination_system->cds_descriptions = VALUE #(
        ( name        = c_cds
          description = VALUE #( fields = VALUE #( ( cds_field( iv_element = 'ItemId' iv_base_field = 'ITEM_ID' ) )
                                                   ( cds_field( iv_element = 'Calc' iv_calculated = abap_true ) ) ) ) ) ).
  ENDMETHOD.

  METHOD given_table_usage.
    repository->references = VALUE #(
        ( reference( is_from = program iv_ref_pgmid = 'R3TR' iv_ref_type = 'TABL' iv_ref_name = c_table ) ) ).
    repository->used_components = VALUE #(
        ( reference( is_from      = program
                     iv_ref_pgmid = ''
                     iv_ref_type  = yif_trm_xref_repository=>c_used_component
                     iv_ref_name  = |{ c_table }~{ iv_used_field }| ) ) ).
    source_system->table_descriptions = VALUE #(
        ( name        = c_table
          description = VALUE #( fields = VALUE #( ( table_field( 'ITEM_ID' ) )
                                                   ( table_field( iv_name = 'AMOUNT' iv_length = 15 ) )
                                                   ( table_field( 'NEW_FIELD' ) ) ) ) ) ).
    destination_system->table_descriptions = VALUE #(
        ( name        = c_table
          description = VALUE #( fields = VALUE #( ( table_field( 'ITEM_ID' ) )
                                                   ( table_field( iv_name = 'AMOUNT' iv_length = 13 ) ) ) ) ) ).
  ENDMETHOD.

  METHOD given_cds_in_request.
    rs_cds = object( iv_pgmid = 'R3TR' iv_type = 'DDLS' iv_name = 'ZTRM_TEST_CDS_WIDE' ).
    repository->references = VALUE #(
        ( reference( is_from = rs_cds iv_ref_pgmid = 'R3TR' iv_ref_type = 'DDLS' iv_ref_name = c_cds ) ) ).
    source_system->cds_descriptions = VALUE #(
        ( name        = rs_cds-obj_name
          description = VALUE #( fields = VALUE #( ( VALUE #( element_name = 'NewField'
                                                              base_object  = c_cds
                                                              base_field   = 'NEWFIELD' ) ) ) ) ) ).
    destination_system->cds_descriptions = VALUE #(
        ( name        = c_cds
          description = VALUE #( fields = COND #( WHEN iv_destination_has_field = abap_true
                                                  THEN VALUE #( ( cds_field( iv_element = 'ItemId' ) )
                                                                ( cds_field( iv_element = 'NewField' ) ) )
                                                  ELSE VALUE #( ( cds_field( iv_element = 'ItemId' ) ) ) ) ) ) ).
  ENDMETHOD.

  METHOD cds_field.
    rs_field = VALUE #( entity_name   = c_cds
                        element_name  = iv_element
                        base_object   = COND #( WHEN iv_base_field IS NOT INITIAL THEN c_table )
                        base_field    = iv_base_field
                        is_calculated = iv_calculated ).
  ENDMETHOD.

  METHOD table_field.
    rs_field = VALUE #( tabname   = c_table
                        fieldname = iv_name
                        datatype  = 'CHAR'
                        leng      = iv_length ).
  ENDMETHOD.

  METHOD given_interface_type_usage.
    repository->types_without_pgmid = VALUE #( ( 'OT' ) ).
    repository->references = VALUE #(
        ( reference( is_from = program iv_ref_pgmid = 'R3TR' iv_ref_type = 'INTF' iv_ref_name = c_interface ) )
        ( reference( is_from = program iv_ref_pgmid = 'R3TR' iv_ref_type = 'OT' iv_ref_name = 'TY_POINT' ) ) ).
    source_system->object_descriptions = VALUE #(
        ( object_name = c_interface
          description = VALUE #( ( sub_object_type = 'OT' sub_object_name = 'TY_POINT' source_code = iv_source_type ) ) ) ).
    destination_system->object_descriptions = VALUE #(
        ( object_name = c_interface
          description = VALUE #( ( sub_object_type = 'OT' sub_object_name = 'TY_POINT' source_code = iv_destination_type ) ) ) ).
  ENDMETHOD.

  METHOD given_class_attribute_usage.
    repository->types_without_pgmid = VALUE #( ( 'ATRB' ) ).
    repository->references = VALUE #(
        ( reference( is_from = program iv_ref_pgmid = 'R3TR' iv_ref_type = 'CLAS' iv_ref_name = c_class ) )
        ( reference( is_from = program iv_ref_pgmid = '' iv_ref_type = 'ATRB' iv_ref_name = |{ c_class }~{ iv_attribute }| ) ) ).
    destination_system->object_descriptions = VALUE #(
        ( object_name = c_class
          description = VALUE #( ( sub_object_type = 'ATRB' sub_object_name = iv_destination_attribute ) ) ) ).
  ENDMETHOD.

  METHOD intf_used_comp_exists_ok.
    given_interface_usage( iv_component_type = 'METH' iv_component_name = 'DO_IT' ).
    destination_system->object_descriptions = VALUE #(
        ( object_name = c_interface
          description = VALUE #( ( sub_object_type = 'METH' sub_object_name = 'DO_IT' ) ) ) ).

    DATA(ls_analysis) = run( VALUE #( ( program ) ) ).

    DATA(ls_result) = result_of( is_analysis = ls_analysis iv_type = 'INTF' iv_name = c_interface ).
    cl_abap_unit_assert=>assert_equals( exp = yif_trm_cross_reference=>c_status-different_but_not_relevant
                                        act = ls_result-status ).
    cl_abap_unit_assert=>assert_equals( exp = icon_led_green
                                        act = ls_result-object_list[ 1 ]-severity ).
  ENDMETHOD.

  METHOD intf_used_comp_missing_error.
    given_interface_usage( iv_component_type = 'METH' iv_component_name = 'DO_IT' ).
    destination_system->object_descriptions = VALUE #(
        ( object_name = c_interface
          description = VALUE #( ( sub_object_type = 'METH' sub_object_name = 'OTHER_METHOD' ) ) ) ).

    DATA(ls_analysis) = run( VALUE #( ( program ) ) ).

    DATA(ls_result) = result_of( is_analysis = ls_analysis iv_type = 'INTF' iv_name = c_interface ).
    cl_abap_unit_assert=>assert_equals( exp = yif_trm_cross_reference=>c_status-different
                                        act = ls_result-status ).
    cl_abap_unit_assert=>assert_equals( exp = icon_led_red
                                        act = ls_result-object_list[ 1 ]-severity ).
    cl_abap_unit_assert=>assert_true( ls_result-object_list[ 1 ]-logger->has_messages( ) ).
  ENDMETHOD.

  METHOD intf_atrb_field_differs_warn.
    given_interface_usage( iv_component_type = 'ATRB' iv_component_name = 'C_CONSTANT' ).
    source_system->object_descriptions = VALUE #(
        ( object_name = c_interface
          description = VALUE #( ( sub_object_type = 'ATRB' sub_object_name = 'C_CONSTANT-FIELD_A' )
                                 ( sub_object_type = 'ATRB' sub_object_name = 'C_CONSTANT-FIELD_B' ) ) ) ).
    destination_system->object_descriptions = VALUE #(
        ( object_name = c_interface
          description = VALUE #( ( sub_object_type = 'ATRB' sub_object_name = 'C_CONSTANT-FIELD_A' ) ) ) ).

    DATA(ls_analysis) = run( VALUE #( ( program ) ) ).

    DATA(ls_result) = result_of( is_analysis = ls_analysis iv_type = 'INTF' iv_name = c_interface ).
    cl_abap_unit_assert=>assert_equals( exp = yif_trm_cross_reference=>c_status-different_in_destination
                                        act = ls_result-status ).
    cl_abap_unit_assert=>assert_equals( exp = icon_led_yellow
                                        act = ls_result-object_list[ 1 ]-severity ).
  ENDMETHOD.

  METHOD intf_atrb_missing_error.
    given_interface_usage( iv_component_type = 'ATRB' iv_component_name = 'C_CONSTANT' ).

    DATA(ls_analysis) = run( VALUE #( ( program ) ) ).

    DATA(ls_result) = result_of( is_analysis = ls_analysis iv_type = 'INTF' iv_name = c_interface ).
    cl_abap_unit_assert=>assert_equals( exp = yif_trm_cross_reference=>c_status-different
                                        act = ls_result-status ).
    cl_abap_unit_assert=>assert_equals( exp = icon_led_red
                                        act = ls_result-object_list[ 1 ]-severity ).
  ENDMETHOD.

  METHOD intf_new_atrb_in_source_error.
    given_interface_usage( iv_component_type = 'ATRB' iv_component_name = 'C_NEW' ).
    source_system->object_descriptions = VALUE #(
        ( object_name = c_interface
          description = VALUE #( ( sub_object_type = 'ATRB' sub_object_name = 'C_NEW' )
                                 ( sub_object_type = 'METH' sub_object_name = 'DO_IT' ) ) ) ).
    destination_system->object_descriptions = VALUE #(
        ( object_name = c_interface
          description = VALUE #( ( sub_object_type = 'METH' sub_object_name = 'DO_IT' ) ) ) ).

    DATA(ls_analysis) = run( VALUE #( ( program ) ) ).

    DATA(ls_result) = result_of( is_analysis = ls_analysis iv_type = 'INTF' iv_name = c_interface ).
    cl_abap_unit_assert=>assert_equals( exp = yif_trm_cross_reference=>c_status-different
                                        act = ls_result-status ).
    cl_abap_unit_assert=>assert_equals( exp = icon_led_red
                                        act = ls_result-object_list[ 1 ]-severity ).
  ENDMETHOD.

  METHOD cpub_methods_exist_irrelevant.
    given_class_part_usage( ).
    given_method_in_systems( iv_object_name        = c_class
                             iv_method_name        = 'DO_IT'
                             is_destination_method = method_description( VALUE #( ) )
                             iv_in_source          = abap_false ).

    DATA(ls_analysis) = run( VALUE #( ( program )
                                      ( object( iv_pgmid = 'LIMU'
                                                iv_type  = 'METH'
                                                iv_name  = method_name( iv_class = c_class iv_method = 'DO_IT' ) ) ) ) ).

    cl_abap_unit_assert=>assert_equals( exp = yif_trm_cross_reference=>c_status-different_but_not_relevant
                                        act = status_of( is_analysis = ls_analysis iv_type = 'CPUB' iv_name = c_class ) ).
  ENDMETHOD.

  METHOD cpub_method_missing_error.
    given_class_part_usage( ).

    DATA(ls_analysis) = run( VALUE #( ( program )
                                      ( object( iv_pgmid = 'LIMU'
                                                iv_type  = 'METH'
                                                iv_name  = method_name( iv_class = c_class iv_method = 'DO_IT' ) ) ) ) ).

    DATA(ls_result) = result_of( is_analysis = ls_analysis iv_type = 'CPUB' iv_name = c_class ).
    cl_abap_unit_assert=>assert_equals( exp = yif_trm_cross_reference=>c_status-different
                                        act = ls_result-status ).
    cl_abap_unit_assert=>assert_equals( exp = icon_led_red
                                        act = ls_result-object_list[ 1 ]-severity ).
  ENDMETHOD.

  METHOD enqueue_with_enqu_in_request.
    given_reference_to_enqueue( ).

    DATA(ls_analysis) = run( VALUE #( ( program )
                                      ( object( iv_pgmid = 'R3TR' iv_type = 'ENQU' iv_name = 'EZTRM_TEST' ) ) ) ).

    cl_abap_unit_assert=>assert_equals(
        exp = yif_trm_cross_reference=>c_status-also_in_transport_request
        act = status_of( is_analysis = ls_analysis iv_type = 'FUNC' iv_name = 'ENQUEUE_EZTRM_TEST' ) ).
  ENDMETHOD.

  METHOD enqueue_enqu_exists_in_dest.
    given_reference_to_enqueue( ).
    destination_system->existing_objects = VALUE #( ( pgmid = 'R3TR' object = 'ENQU' obj_name = 'EZTRM_TEST' ) ).

    DATA(ls_analysis) = run( VALUE #( ( program ) ) ).

    cl_abap_unit_assert=>assert_equals(
        exp = yif_trm_cross_reference=>c_status-exist_in_destination
        act = status_of( is_analysis = ls_analysis iv_type = 'FUNC' iv_name = 'ENQUEUE_EZTRM_TEST' ) ).
  ENDMETHOD.

  METHOD enqueue_enqu_only_in_source.
    given_reference_to_enqueue( ).

    DATA(ls_analysis) = run( VALUE #( ( program ) ) ).

    cl_abap_unit_assert=>assert_equals(
        exp = yif_trm_cross_reference=>c_status-only_in_source
        act = status_of( is_analysis = ls_analysis iv_type = 'FUNC' iv_name = 'ENQUEUE_EZTRM_TEST' ) ).
  ENDMETHOD.

  METHOD abstract_meth_class_in_request.
    DATA(lv_method) = given_interface_method_ref( iv_abstract = abap_true ).

    DATA(ls_analysis) = run( VALUE #( ( program )
                                      ( object( iv_pgmid = 'R3TR' iv_type = 'CLAS' iv_name = c_class ) ) ) ).

    cl_abap_unit_assert=>assert_equals( exp = yif_trm_cross_reference=>c_status-also_in_transport_request
                                        act = status_of( is_analysis = ls_analysis iv_type = 'METH' iv_name = lv_method ) ).
  ENDMETHOD.

  METHOD abstract_meth_part_in_request.
    DATA(lv_method) = given_interface_method_ref( iv_abstract = abap_true ).

    DATA(ls_analysis) = run( VALUE #( ( program )
                                      ( object( iv_pgmid = 'LIMU' iv_type = 'CPUB' iv_name = c_class ) ) ) ).

    cl_abap_unit_assert=>assert_equals( exp = yif_trm_cross_reference=>c_status-also_in_transport_request
                                        act = status_of( is_analysis = ls_analysis iv_type = 'METH' iv_name = lv_method ) ).
  ENDMETHOD.

  METHOD abstract_meth_not_in_request.
    DATA(lv_method) = given_interface_method_ref( iv_abstract = abap_true ).

    DATA(ls_analysis) = run( VALUE #( ( program ) ) ).

    cl_abap_unit_assert=>assert_equals( exp = yif_trm_cross_reference=>c_status-only_in_source
                                        act = status_of( is_analysis = ls_analysis iv_type = 'METH' iv_name = lv_method ) ).
  ENDMETHOD.

  METHOD not_abstract_meth_unchanged.
    DATA(lv_method) = given_interface_method_ref( iv_abstract = abap_false ).

    DATA(ls_analysis) = run( VALUE #( ( program )
                                      ( object( iv_pgmid = 'R3TR' iv_type = 'CLAS' iv_name = c_class ) ) ) ).

    cl_abap_unit_assert=>assert_equals( exp = yif_trm_cross_reference=>c_status-only_in_source
                                        act = status_of( is_analysis = ls_analysis iv_type = 'METH' iv_name = lv_method ) ).
  ENDMETHOD.

  METHOD given_interface_method_ref.
    rv_method = method_name( iv_class = c_class iv_method = |{ c_interface }~CALCULATE| ).
    repository->references = VALUE #(
        ( reference( is_from = program iv_ref_pgmid = 'LIMU' iv_ref_type = 'METH' iv_ref_name = rv_method ) ) ).
    IF iv_abstract = abap_true.
      repository->abstract_methods = VALUE #( ( rv_method ) ).
    ENDIF.
  ENDMETHOD.

  METHOD given_reference_to_enqueue.
    repository->references = VALUE #(
        ( reference( is_from = program iv_ref_pgmid = 'R3TR' iv_ref_type = 'FUNC' iv_ref_name = 'ENQUEUE_EZTRM_TEST' ) ) ).
  ENDMETHOD.

  METHOD object.
    rs_object = VALUE #( pgmid = iv_pgmid obj_type = iv_type obj_name = iv_name ).
  ENDMETHOD.

  METHOD reference.
    rs_reference = VALUE #( pgmid        = is_from-pgmid
                            obj_type     = is_from-obj_type
                            obj_name     = is_from-obj_name
                            ref_pgmid    = iv_ref_pgmid
                            ref_obj_type = iv_ref_type
                            ref_obj_name = iv_ref_name ).
  ENDMETHOD.

  METHOD method_name.
    rv_name = iv_class.
    rv_name+30 = iv_method.
  ENDMETHOD.

  METHOD parameter.
    rs_parameter = VALUE #( sconame = iv_name type = iv_type paroptionl = iv_optional ).
  ENDMETHOD.

  METHOD method_description.
    rs_description = VALUE #( defined_in = VALUE #( object_pgmid = 'LIMU'
                                                    object_type  = iv_defined_in_type
                                                    object_name  = c_class )
                              parameters = it_parameters ).
  ENDMETHOD.

  METHOD given_reference_to_dtel.
    repository->references = VALUE #(
        ( reference( is_from = program iv_ref_pgmid = 'R3TR' iv_ref_type = 'DTEL' iv_ref_name = c_dtel ) ) ).
  ENDMETHOD.

  METHOD given_method_reference.
    repository->references = VALUE #(
        ( reference( is_from      = program
                     iv_ref_pgmid = 'LIMU'
                     iv_ref_type  = 'METH'
                     iv_ref_name  = method_name( iv_class = c_class iv_method = iv_method ) ) ) ).
  ENDMETHOD.

  METHOD given_method_in_systems.
    IF iv_in_source = abap_true.
      INSERT VALUE #( object_name = iv_object_name
                      method_name = iv_method_name
                      description = is_source_method ) INTO TABLE source_system->method_descriptions.
    ENDIF.

    IF iv_in_destination = abap_true.
      INSERT VALUE #( object_name = iv_object_name
                      method_name = iv_method_name
                      description = is_destination_method ) INTO TABLE destination_system->method_descriptions.
    ENDIF.
  ENDMETHOD.

  METHOD given_interface_usage.
    repository->types_without_pgmid = VALUE #( ( iv_component_type ) ).
    repository->references = VALUE #(
        ( reference( is_from = program iv_ref_pgmid = 'R3TR' iv_ref_type = 'INTF' iv_ref_name = c_interface ) )
        ( reference( is_from      = program
                     iv_ref_pgmid = 'LIMU'
                     iv_ref_type  = iv_component_type
                     iv_ref_name  = |{ c_interface }~{ iv_component_name }| ) ) ).
  ENDMETHOD.

  METHOD given_class_part_usage.
    repository->resolved_methods = VALUE #(
        ( pgmid    = 'CPUB'
          obj_type = 'METH'
          obj_name = method_name( iv_class = c_class iv_method = 'DO_IT' ) ) ).
  ENDMETHOD.

  METHOD run.
    rs_analysis = cut->run( it_objects ).
  ENDMETHOD.

  METHOD has_result.
    LOOP AT is_analysis-result INTO DATA(lo_reference).
      DATA(ls_data) = lo_reference->get_data( ).
      IF ls_data-reference_fragment = iv_type AND ls_data-reference_fragname = iv_name.
        RETURN abap_true.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD result_of.
    LOOP AT is_analysis-result INTO DATA(lo_reference).
      rs_result = lo_reference->get_data( ).
      IF rs_result-reference_fragment = iv_type AND rs_result-reference_fragname = iv_name.
        RETURN.
      ENDIF.
    ENDLOOP.

    cl_abap_unit_assert=>fail( |Reference { iv_type } { iv_name } not found| ).
  ENDMETHOD.

  METHOD status_of.
    rv_status = result_of( is_analysis = is_analysis iv_type = iv_type iv_name = iv_name )-status.
  ENDMETHOD.

ENDCLASS.
