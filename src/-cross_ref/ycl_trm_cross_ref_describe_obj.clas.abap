CLASS ycl_trm_cross_ref_describe_obj DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES yif_trm_xref_system.

    ALIASES describe FOR yif_trm_xref_system~describe.

    TYPES ty_t_description TYPE yif_trm_xref_system=>ty_t_description.

    "! @parameter iv_rfc_comparison | System to describe; NONE for the local system
    METHODS constructor
      IMPORTING iv_rfc_comparison TYPE rfcdes-rfcdest.

  PRIVATE SECTION.
    TYPES ty_t_seoaliases TYPE STANDARD TABLE OF seoaliases WITH DEFAULT KEY.

    TYPES: BEGIN OF ty_s_describe_cache,
             object_name TYPE vrsd-objname,
             description TYPE ty_t_description,
           END OF ty_s_describe_cache,
           ty_t_describe_cache TYPE STANDARD TABLE OF ty_s_describe_cache WITH NON-UNIQUE KEY object_name.

    DATA rfc_destination TYPE rfcdes-rfcdest.

    CONSTANTS: BEGIN OF c_cpub_cpro_cpri,
                 cpub TYPE string VALUE 'CPUB',
                 cpro TYPE string VALUE 'CPRO',
                 cpri TYPE string VALUE 'CPRI',
               END OF c_cpub_cpro_cpri.

    DATA t_describe_cache   TYPE ty_t_describe_cache.
    DATA t_badi_spot        TYPE STANDARD TABLE OF badi_spot WITH DEFAULT KEY WITH NON-UNIQUE SORTED KEY sorted_badi_name COMPONENTS badi_name.
    DATA badi_spots_loaded  TYPE abap_bool.

    METHODS find_in_cache
      IMPORTING iv_object_name        TYPE vrsd-objname
      RETURNING VALUE(rt_description) TYPE ty_t_description
      RAISING   cx_sy_itab_line_not_found.

    METHODS save_in_cache
      IMPORTING iv_object_name TYPE vrsd-objname
                it_description TYPE ty_t_description.

    "! Destination for RFC calls: NONE for the local system
    METHODS rfc_call_destination
      RETURNING VALUE(rv_destination) TYPE rfcdes-rfcdest.

    METHODS not_found
      IMPORTING iv_type         TYPE trobjtype
                iv_name         TYPE csequence
      RETURNING VALUE(rx_error) TYPE REF TO ycx_trm_cross_reference.

    METHODS add_from_alias
      IMPORTING it_aliases            TYPE ty_t_seoaliases
      RETURNING VALUE(rt_description) TYPE ty_t_description.

    METHODS class
      IMPORTING iv_object_name        TYPE vrsd-objname
      RETURNING VALUE(rt_description) TYPE ty_t_description
      RAISING   ycx_trm_cross_reference.

    METHODS interface
      IMPORTING iv_object_name        TYPE vrsd-objname
      RETURNING VALUE(rt_description) TYPE ty_t_description
      RAISING   ycx_trm_cross_reference.

    METHODS cpub_cpro_cpri
      IMPORTING iv_object_name        TYPE vrsd-objname
                iv_cpub_cpro_cpri     TYPE string
      RETURNING VALUE(rt_description) TYPE ty_t_description
      RAISING   ycx_trm_cross_reference.

    METHODS enchancement_spot
      IMPORTING iv_object_name               TYPE versobjnam
      RETURNING VALUE(rv_badi_def_interface) TYPE vrsd-objname
      RAISING   ycx_trm_cross_reference.

    METHODS badi_definition
      IMPORTING iv_object_name             TYPE vrsd-objname
      RETURNING VALUE(rv_enhancement_spot) TYPE vrsd-objname
      RAISING   ycx_trm_cross_reference.

ENDCLASS.


CLASS ycl_trm_cross_ref_describe_obj IMPLEMENTATION.

  METHOD constructor.
    rfc_destination = iv_rfc_comparison.
    IF rfc_destination = 'NONE'.
      CLEAR rfc_destination.
    ENDIF.
  ENDMETHOD.

  METHOD rfc_call_destination.
    rv_destination = COND #( WHEN rfc_destination IS INITIAL THEN 'NONE' ELSE rfc_destination ).
  ENDMETHOD.

  METHOD yif_trm_xref_system~describe.

    TRY.
        RETURN find_in_cache( iv_object_name  ).
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    DATA lv_object_type TYPE trobjtype.

    DATA(lv_object_name) = iv_object_name.

    " The type is determined in the described system: it can be a different object in the local system
    IF yif_trm_xref_system~object_exists( iv_pgmid    = 'R3TR'
                                          iv_object   = 'CLAS'
                                          iv_obj_name = CONV #( iv_object_name ) ).
      lv_object_type = 'CLAS'.
    ELSEIF yif_trm_xref_system~object_exists( iv_pgmid    = 'R3TR'
                                              iv_object   = 'INTF'
                                              iv_obj_name = CONV #( iv_object_name ) ).
      lv_object_type = 'INTF'.
    ELSE.

      " Las BADIs no están en la tadir
      lv_object_name = badi_definition( iv_object_name ).
      IF lv_object_name IS NOT INITIAL.
        lv_object_type = 'ENHS'.
      ENDIF.

    ENDIF.

    CASE lv_object_type.

      WHEN 'CLAS'.
        DATA(lt_description) = class( lv_object_name ).

      WHEN 'INTF'.
        lt_description = interface( lv_object_name ).

      WHEN 'ENHS'. " Enhancement Spot -> BADI definition
        " Cuando el método está definido en la interfaz de una BADI,
        " aqui llega el nombre de la BADI, no del Enhancement Spot
        lt_description = describe( enchancement_spot( lv_object_name ) ).

      WHEN OTHERS.
    ENDCASE.

    " Save cache
    save_in_cache( iv_object_name = iv_object_name
                   it_description = lt_description ).

    RETURN lt_description.
  ENDMETHOD.

  METHOD interface.
    DATA lv_object_name       TYPE vrsd-objname.
    DATA lt_vsmodisrc         TYPE STANDARD TABLE OF smodisrc.
    DATA lt_pseoaliases       TYPE STANDARD TABLE OF seoaliases.
    DATA lt_dpvseoattrib      TYPE STANDARD TABLE OF vseoattrib_vrs.
    DATA lt_dpvseocompri      TYPE STANDARD TABLE OF vseocompri.
    DATA lt_dpvseoevent       TYPE STANDARD TABLE OF vseoevent.
    DATA lt_dpvseoexcep       TYPE STANDARD TABLE OF vseoexcep.
    DATA lt_dpvseointerf      TYPE STANDARD TABLE OF vseointerf.
    DATA lt_dpsmodilog        TYPE STANDARD TABLE OF smodilog.
    DATA lt_dpvseomethod      TYPE STANDARD TABLE OF vseomethod.
    DATA lt_dpvseoparam       TYPE STANDARD TABLE OF vseoparam.
    DATA lt_dppool_source     TYPE STANDARD TABLE OF abaptxt255.
    DATA lt_dpsource          TYPE STANDARD TABLE OF abaptxt255.
    DATA lt_dptrdir           TYPE STANDARD TABLE OF trdir.
    DATA lt_dtype_tab         TYPE STANDARD TABLE OF vseotype_vrs.
    DATA lt_dpseotypepls      TYPE STANDARD TABLE OF seotypepls.
    DATA lt_attributes_result TYPE ytrm_t_descr_atrb_result.

    lv_object_name = iv_object_name.

    CALL FUNCTION 'SVRS_GET_VERSION_INTF_40'
      EXPORTING  destination           = rfc_destination
                 object_name           = lv_object_name
                 versno                = CONV vrsd-versno( '00000' )
      TABLES     vsmodisrc             = lt_vsmodisrc
                 pseoaliases           = lt_pseoaliases
                 pvseoattrib           = lt_dpvseoattrib
                 pvseocompri           = lt_dpvseocompri
                 pvseoevent            = lt_dpvseoevent
                 pvseoexcep            = lt_dpvseoexcep
                 pvseointerf           = lt_dpvseointerf
                 psmodilog             = lt_dpsmodilog
                 pvseomethod           = lt_dpvseomethod
                 pvseoparam            = lt_dpvseoparam
                 ppool_source          = lt_dppool_source
                 psource               = lt_dpsource
                 ptrdir                = lt_dptrdir
                 type_tab              = lt_dtype_tab
                 pseotypepls           = lt_dpseotypepls
      EXCEPTIONS no_version            = 1
                 system_failure        = 2
                 communication_failure = 3
                 OTHERS                = 4.
    IF sy-subrc <> 0.
      DATA(ls_msg) = CORRESPONDING bal_s_msg( sy ).
      DATA(lo_log) = ycl_trm_logger=>new( ).
      lo_log->add_message( ls_msg ).
      RAISE EXCEPTION NEW ycx_trm_cross_reference( logger = lo_log ).
    ENDIF.

    " Methods
    rt_description = VALUE #( BASE rt_description FOR ls_seomethod IN lt_dpvseomethod
                              ( object_pgmid    = 'R3TR'
                                object_type     = 'INTF'
                                object_name     = lv_object_name
                                sub_object_type = 'METH'
                                sub_object_name = ls_seomethod-cmpname
                                source_code     = '' ) ).

    " Atributos
    rt_description = VALUE #( BASE rt_description FOR ls_seoattrib IN lt_dpvseoattrib
                              ( object_pgmid    = 'R3TR'
                                object_type     = 'INTF'
                                object_name     = lv_object_name
                                sub_object_type = 'ATRB'
                                sub_object_name = ls_seoattrib-cmpname
                                source_code     = COND #( WHEN ls_seoattrib-type IS NOT INITIAL
                                                          THEN ls_seoattrib-type
                                                          ELSE ls_seoattrib-typesrc ) ) ).

    " Alias
    INSERT LINES OF add_from_alias( lt_pseoaliases ) INTO TABLE rt_description.

    " Tipos
    rt_description = VALUE #( BASE rt_description FOR ls_dype IN lt_dtype_tab
                              ( object_pgmid    = 'R3TR'
                                object_type     = 'INTF'
                                object_name     = lv_object_name
                                sub_object_type = 'OT'
                                sub_object_name = ls_dype-cmpname
                                source_code     = ls_dype-typesrc ) ).

    " events
    rt_description = VALUE #( BASE rt_description FOR ls_seoevent IN lt_dpvseoevent
                              ( object_pgmid    = 'R3TR'
                                object_type     = 'INTF'
                                object_name     = lv_object_name
                                sub_object_type = 'EVNT'
                                sub_object_name = ls_seoevent-cmpname
                                source_code     = '' ) ).

    " Add method descrition
    LOOP AT rt_description ASSIGNING FIELD-SYMBOL(<ls_description>) WHERE sub_object_type = 'METH'.

      IF <ls_description>-sub_object_name_alias IS NOT INITIAL.
        CONTINUE.
      ENDIF.

      <ls_description>-method_description-defined_in = CORRESPONDING #( <ls_description> ).

      <ls_description>-method_description-parameters = VALUE #( BASE <ls_description>-method_description-parameters FOR ls_param IN lt_dpvseoparam WHERE ( cmpname = <ls_description>-sub_object_name )
                                                                ( ls_param ) ).

      <ls_description>-method_description-exceptions = VALUE #( BASE <ls_description>-method_description-exceptions FOR ls_exception IN lt_dpvseoexcep WHERE ( cmpname = <ls_description>-sub_object_name )
                                                                ( ls_exception ) ).

    ENDLOOP.

    " Describir los atributos
    DATA(lt_attributes) = VALUE ytrm_t_descr_atrb( FOR rs_description IN rt_description WHERE ( sub_object_type = 'ATRB' )
                                                   ( CORRESPONDING #( rs_description ) ) ).
    IF lt_attributes IS NOT INITIAL.

      FINAL(lv_destination) = rfc_call_destination( ).
      CALL FUNCTION 'YTRM_FM_CROSS_REF_DESCR_ATRB' DESTINATION lv_destination
        TABLES attributes = lt_attributes
               result     = lt_attributes_result.

      LOOP AT lt_attributes_result ASSIGNING FIELD-SYMBOL(<ls_attribute_result>).

        DELETE rt_description WHERE     object_name     = <ls_attribute_result>-object_name
                                    AND sub_object_type = 'ATRB'
                                    AND sub_object_name = <ls_attribute_result>-sub_object_name.

        INSERT VALUE #(
            object_pgmid    = 'R3TR'
            object_type     = 'INTF'
            object_name     = <ls_attribute_result>-object_name
            sub_object_type = 'ATRB'
            sub_object_name = COND #( WHEN <ls_attribute_result>-path IS NOT INITIAL
                                      THEN |{ <ls_attribute_result>-sub_object_name }-{ <ls_attribute_result>-path }|
                                      ELSE <ls_attribute_result>-sub_object_name ) ) INTO TABLE rt_description.

      ENDLOOP.

    ENDIF.

  ENDMETHOD.

  METHOD class.
    DATA lv_object_name TYPE vrsd-objname.
    DATA lt_pseometarel TYPE STANDARD TABLE OF seometarel.

    lv_object_name = iv_object_name.

    CALL FUNCTION 'SVRS_GET_VERSION_CLSD_40'
      EXPORTING  destination           = rfc_destination
                 object_name           = iv_object_name
                 versno                = CONV vrsd-versno( '00000' )
      TABLES     pseometarel           = lt_pseometarel
      EXCEPTIONS no_version            = 1
                 system_failure        = 2
                 communication_failure = 3
                 OTHERS                = 4.
    IF sy-subrc <> 0.
      DATA(ls_msg) = CORRESPONDING bal_s_msg( sy ).
      DATA(lo_log) = ycl_trm_logger=>new( ).
      lo_log->add_message( ls_msg ).
      RAISE EXCEPTION NEW ycx_trm_cross_reference( logger = lo_log ).
    ENDIF.

    DATA(lv_inherating_from) = VALUE #( lt_pseometarel[ 1 ]-refclsname OPTIONAL ).
    IF lv_inherating_from IS NOT INITIAL.
      rt_description = describe( CONV #( lv_inherating_from ) ).

      LOOP AT rt_description ASSIGNING FIELD-SYMBOL(<ls_description>) WHERE object_name = lv_inherating_from.

        " Change name
        <ls_description>-object_name = lv_object_name.

        " Delete private part
        IF <ls_description>-object_type = 'CPRI'.
          DELETE TABLE rt_description FROM <ls_description>.
          CONTINUE.
        ENDIF.

      ENDLOOP.

      " El constructor de la herencia solo tiene que ir si la clase no lo tiene re-definido
      DATA(ls_inherating_constructor) = VALUE #( rt_description[ sub_object_type = 'METH'
                                                                 sub_object_name = 'CONSTRUCTOR' ] OPTIONAL ).
      DELETE rt_description WHERE sub_object_type = 'METH' AND sub_object_name = 'CONSTRUCTOR'.

    ENDIF.

    rt_description = VALUE #( BASE rt_description
                              FOR ls_cpub_description IN cpub_cpro_cpri( iv_object_name    = iv_object_name
                                                                         iv_cpub_cpro_cpri = c_cpub_cpro_cpri-cpub )
                              ( ls_cpub_description ) ).
    rt_description = VALUE #( BASE rt_description
                              FOR ls_cpro_description IN cpub_cpro_cpri( iv_object_name    = iv_object_name
                                                                         iv_cpub_cpro_cpri = c_cpub_cpro_cpri-cpro )
                              ( ls_cpro_description ) ).
    rt_description = VALUE #( BASE rt_description
                              FOR ls_cpri_description IN cpub_cpro_cpri( iv_object_name    = iv_object_name
                                                                         iv_cpub_cpro_cpri = c_cpub_cpro_cpri-cpri )
                              ( ls_cpri_description ) ).

    " Las redefiniciones pueden venir repetidas tanto por la herencia como por la redefinition...
    SORT rt_description.
    DELETE ADJACENT DUPLICATES FROM rt_description.

    " El constructor de la herencia solo tiene que ir si la clase no lo tiene re-definido
    IF     NOT line_exists( rt_description[ sub_object_type = 'METH'
                                            sub_object_name = 'CONSTRUCTOR' ] )
       AND     ls_inherating_constructor IS NOT INITIAL.
      INSERT ls_inherating_constructor INTO TABLE rt_description.
    ENDIF.
  ENDMETHOD.

  METHOD add_from_alias.
    LOOP AT it_aliases ASSIGNING FIELD-SYMBOL(<ls_aliases>).

      TRY.
          DATA(lt_description) = describe( CONV #( <ls_aliases>-refclsname ) ).
        CATCH ycx_trm_cross_reference.
          CONTINUE.
      ENDTRY.

      TRY.
          DATA(ls_description) = lt_description[ sub_object_name = <ls_aliases>-refcmpname ].
        CATCH cx_sy_itab_line_not_found.
          ls_description = VALUE #( lt_description[ sub_object_name_alias = <ls_aliases>-cmpname ] OPTIONAL ).
      ENDTRY.

      IF ls_description IS INITIAL.
        CONTINUE.
      ENDIF.

      ls_description-object_name           = <ls_aliases>-clsname.
      ls_description-sub_object_name       = |{ <ls_aliases>-refclsname }~{ <ls_aliases>-refcmpname }|.
      ls_description-sub_object_name_alias = CONV #( <ls_aliases>-cmpname ).
      rt_description = VALUE #( BASE rt_description
                                ( ls_description ) ).

    ENDLOOP.
  ENDMETHOD.

  METHOD yif_trm_xref_system~describe_method.
    DATA(lt_object_descr) = describe( CONV #( iv_object_name ) ).

    TRY.
        rs_description = lt_object_descr[ sub_object_type = 'METH'
                                          sub_object_name = iv_method_name ]-method_description.

      CATCH cx_sy_itab_line_not_found.

        TRY.

            rs_description = lt_object_descr[ sub_object_type       = 'METH'
                                              sub_object_name_alias = iv_method_name ]-method_description.

          CATCH cx_sy_itab_line_not_found.
            DATA(lo_log) = ycl_trm_logger=>new( ).
            MESSAGE e018(ytrm) WITH iv_method_name rfc_destination INTO DATA(lv_dummy) ##NEEDED.
            lo_log->add_message( CORRESPONDING #( sy ) ).
            RAISE EXCEPTION NEW ycx_trm_cross_reference( logger = lo_log ).

        ENDTRY.

    ENDTRY.
  ENDMETHOD.

  METHOD yif_trm_xref_system~describe_table.
    DATA lv_object_name TYPE vrsd-objname.

    lv_object_name = iv_table_name.

    CALL FUNCTION 'SVRS_GET_VERSION_TABD_40'
      EXPORTING  destination           = rfc_destination
                 object_name           = lv_object_name
                 versno                = CONV vrsd-versno( '00000' )
*                 iv_no_release_transformation =
*          IMPORTING
*                 info_line             =
      TABLES
*                 vsmodisrc             =
*                 dd02tv_tab            =
*                 dd02v_tab             =
*                 dd03tv_tab            =
                 dd03v_tab             = rs_description-fields
*                 dd05v_tab             =
*                 dd08tv_tab            =
*                 dd08v_tab             =
*                 dd35v_tab             =
*                 dd36v_tab             =
*                 vsmodilog             =
      EXCEPTIONS no_version            = 1
                 system_failure        = 2
                 communication_failure = 3
                 OTHERS                = 4.
    IF sy-subrc <> 0.
      RAISE EXCEPTION not_found( iv_type = 'TABD'
                                 iv_name = iv_table_name ).
    ENDIF.
  ENDMETHOD.

  METHOD yif_trm_xref_system~describe_cds.
    DATA lv_object_name TYPE vrsd-objname.

    lv_object_name = iv_cds_name.

    FINAL(lv_rfc_destination) = rfc_call_destination( ).

    CALL FUNCTION 'YTRM_FM_CROSS_REF_DESCR_DDLS' DESTINATION lv_rfc_destination
      EXPORTING ddlname = lv_object_name
      TABLES    fields  = rs_description-fields.

    IF rs_description-fields IS INITIAL.
      RAISE EXCEPTION not_found( iv_type = 'DDLS'
                                 iv_name = iv_cds_name ).
    ENDIF.
  ENDMETHOD.

  METHOD not_found.
    FINAL(lo_log) = ycl_trm_logger=>new( ).
    lo_log->add_text( |{ iv_type } { iv_name } not found in { rfc_call_destination( ) }| ).
    rx_error = NEW #( logger = lo_log ).
  ENDMETHOD.

  METHOD yif_trm_xref_system~describe_class_part.
    RETURN cpub_cpro_cpri( iv_cpub_cpro_cpri = CONV #( iv_part )
                           iv_object_name    = iv_object_name ).
  ENDMETHOD.

  METHOD yif_trm_xref_system~compare_versions.
    DATA ls_rfcsi_a TYPE rfcsi.
    DATA ls_rfcsi_b TYPE rfcsi.
    DATA lt_nonvers TYPE TABLE OF e071.

    DATA(lv_filter_lang) = abap_true.
    DATA(lv_delete_lang) = ' '.
    FINAL(lv_destination) = rfc_call_destination( ).

    CALL FUNCTION 'SVRS_MASSCOMPARE_ACT_OBJECTS'
      EXPORTING  it_e071                = it_objects
                 iv_rfcdest_b           = lv_destination
                 iv_filter_lang         = lv_filter_lang
                 iv_delete_lang         = lv_delete_lang
                 iv_with_gui_progress   = abap_false
                 iv_ignore_report_text  = 'X'
      IMPORTING  et_compare_items       = rt_comparison
                 es_rfcsi_a             = ls_rfcsi_a
                 es_rfcsi_b             = ls_rfcsi_b
                 et_nonversionable_e071 = lt_nonvers
      EXCEPTIONS rfc_error              = 1
                 not_supported          = 2
                 OTHERS                 = 3.
    CASE sy-subrc.
      WHEN 0.
      WHEN 1.
        FINAL(lo_log) = ycl_trm_logger=>new( ).
        MESSAGE i008(tsys) WITH lv_destination INTO FINAL(lv_message) ##NEEDED.
        lo_log->add_from_system_variables( ).
        RAISE EXCEPTION NEW ycx_trm_cross_reference( logger = lo_log ).
      WHEN OTHERS.
        MESSAGE i015(tsys).
    ENDCASE.
  ENDMETHOD.

  METHOD yif_trm_xref_system~object_exists.
    DATA lv_exist TYPE strl_pari-flag.

    FINAL(lv_destination) = rfc_call_destination( ).

    CALL FUNCTION 'YTRM_FM_CROSS_REF_EXISTS' DESTINATION lv_destination
      EXPORTING  iv_pgmid              = iv_pgmid
                 iv_object             = iv_object
                 iv_obj_name           = iv_obj_name
      IMPORTING  e_exist               = lv_exist
      EXCEPTIONS system_failure        = 1
                 communication_failure = 2
                 OTHERS                = 3.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    rv_result = xsdbool( lv_exist = abap_true ).
  ENDMETHOD.

  METHOD cpub_cpro_cpri.
    DATA lv_object_name TYPE vrsd-objname.
    DATA lt_seoalias    TYPE STANDARD TABLE OF seoaliases.
    DATA lt_seoattrib   TYPE STANDARD TABLE OF vseoattrib_vrs.
    DATA lt_seoevent    TYPE STANDARD TABLE OF vseoevent.
    DATA lt_seomethod   TYPE STANDARD TABLE OF vseomethod.
    DATA lt_seotype     TYPE STANDARD TABLE OF vseotype.
    DATA lt_source      TYPE STANDARD TABLE OF abaptxt255.
    DATA lt_seoparam    TYPE STANDARD TABLE OF vseoparam.
    DATA lt_seoexcep    TYPE STANDARD TABLE OF vseoexcep.
    DATA lt_seoredef    TYPE STANDARD TABLE OF seoredef.

    DATA(lv_cache_name) = |{ iv_cpub_cpro_cpri }-{ iv_object_name }|.
    TRY.
        RETURN find_in_cache( CONV #( lv_cache_name ) ).
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    IF 1 = 2.
      CALL FUNCTION 'SVRS_GET_VERSION_CPUB_40'.
      CALL FUNCTION 'SVRS_GET_VERSION_CPRO_40'.
      CALL FUNCTION 'SVRS_GET_VERSION_CPRI_40'.
    ENDIF.

    DATA(lv_function_name) = |SVRS_GET_VERSION_{ iv_cpub_cpro_cpri }_40|.
    lv_object_name = iv_object_name.

    CALL FUNCTION lv_function_name
      EXPORTING  destination           = rfc_destination
                 object_name           = lv_object_name
                 versno                = CONV vrsd-versno( '00000' )
      TABLES     pseoalias             = lt_seoalias
                 pvseoattrib           = lt_seoattrib
                 pvseoevent            = lt_seoevent
                 pvseomethod           = lt_seomethod
                 pvseotype             = lt_seotype
                 psource               = lt_source
                 pvseoparam            = lt_seoparam
                 pvseoexcep            = lt_seoexcep
                 pseoredef             = lt_seoredef
      EXCEPTIONS no_version            = 1
                 system_failure        = 2
                 communication_failure = 3
                 OTHERS                = 4.

    " Methods
    rt_description = VALUE #( BASE rt_description FOR ls_seomethod IN lt_seomethod
                              ( object_pgmid    = 'LIMU'
                                object_type     = iv_cpub_cpro_cpri
                                object_name     = lv_object_name
                                sub_object_type = 'METH'
                                sub_object_name = ls_seomethod-cmpname
                                source_code     = '' ) ).

    LOOP AT rt_description ASSIGNING FIELD-SYMBOL(<ls_description>) WHERE sub_object_type = 'METH'.

      <ls_description>-method_description-defined_in = CORRESPONDING #( <ls_description> ).

      <ls_description>-method_description-parameters = VALUE #( BASE <ls_description>-method_description-parameters FOR ls_seoparam IN lt_seoparam WHERE ( cmpname = <ls_description>-sub_object_name )
                                                                ( ls_seoparam ) ).

      <ls_description>-method_description-exceptions = VALUE #( BASE <ls_description>-method_description-exceptions FOR ls_seoexcep IN lt_seoexcep WHERE ( cmpname = <ls_description>-sub_object_name )
                                                                ( ls_seoexcep ) ).

    ENDLOOP.

    " Redefinitions
    LOOP AT lt_seoredef ASSIGNING FIELD-SYMBOL(<ls_seoredef>).

      DATA(lt_refclsname_description) = describe( CONV #( <ls_seoredef>-refclsname ) ).

      INSERT VALUE #(
          object_pgmid       = 'LIMU'
          object_type        = iv_cpub_cpro_cpri
          object_name        = lv_object_name
          sub_object_type    = 'METH'
          sub_object_name    = <ls_seoredef>-mtdname
          method_description = VALUE #( lt_refclsname_description[
                                            sub_object_name = <ls_seoredef>-mtdname ]-method_description OPTIONAL )
          source_code        = '' )
             INTO TABLE rt_description.

    ENDLOOP.

    " Atributos
    rt_description = VALUE #( BASE rt_description FOR ls_seoattrib IN lt_seoattrib
                              ( object_pgmid    = 'LIMU'
                                object_type     = iv_cpub_cpro_cpri
                                object_name     = lv_object_name
                                sub_object_type = 'ATRB'
                                sub_object_name = ls_seoattrib-cmpname
                                source_code     = ls_seoattrib-type  ) ).
    " Alias
    rt_description = VALUE #( BASE rt_description FOR ls_alias IN add_from_alias( lt_seoalias )
                              ( object_pgmid          = 'LIMU'
                                object_type           = iv_cpub_cpro_cpri
                                object_name           = ls_alias-object_name
                                sub_object_type       = ls_alias-sub_object_type
                                sub_object_name       = ls_alias-sub_object_name
                                sub_object_name_alias = ls_alias-sub_object_name_alias
                                source_code           = ls_alias-source_code  ) ).

    " Tipos
    rt_description = VALUE #( BASE rt_description FOR ls_seotype IN lt_seotype
                              ( object_pgmid    = 'LIMU'
                                object_type     = iv_cpub_cpro_cpri
                                object_name     = lv_object_name
                                sub_object_type = 'OT'
                                sub_object_name = ls_seotype-cmpname
                                source_code     = ls_seotype-typesrc ) ).

    " events
    rt_description = VALUE #( BASE rt_description FOR ls_seoevent IN lt_seoevent
                              ( object_pgmid    = 'LIMU'
                                object_type     = iv_cpub_cpro_cpri
                                object_name     = lv_object_name
                                sub_object_type = 'EVNT'
                                sub_object_name = ls_seoevent-cmpname
                                source_code     = '' ) ).

    save_in_cache( iv_object_name = CONV #( lv_cache_name )
                   it_description = rt_description ).
  ENDMETHOD.

  METHOD find_in_cache.
    RETURN t_describe_cache[ object_name = iv_object_name ]-description.
  ENDMETHOD.

  METHOD save_in_cache.
    INSERT VALUE #( object_name = iv_object_name
                    description = it_description ) INTO TABLE t_describe_cache.
  ENDMETHOD.

  METHOD enchancement_spot.

    DATA lt_spobj_tab TYPE STANDARD TABLE OF enhspotobj WITH DEFAULT KEY.

    IF iv_object_name IS INITIAL.
      RETURN.
    ENDIF.

    CALL FUNCTION 'SVRS_GET_VERSION_ENHS_40'
      EXPORTING  destination           = rfc_destination
                 object_name           = iv_object_name
                 versno                = CONV vrsd-versno( '00000' )
*                 iv_no_release_transformation =
*      IMPORTING
*                 info_line             =
      TABLES
*                 vsmodisrc             =
*                 cdata_tab             =
*                 cvers_tab             =
*                 encrs_tab             =
*                 enhspottextab_tab     =
*                 enhtext_tab           =
*                 enhtextv_tab          =
*                 hdata_tab             =
*                 hvers_tab             =
*                 mdlog_tab             =
                 spobj_tab             = lt_spobj_tab
      EXCEPTIONS no_version            = 1
                 system_failure        = 2
                 communication_failure = 3
                 OTHERS                = 4.

    rv_badi_def_interface = VALUE #( lt_spobj_tab[ obj_type = 'INTF' ]-obj_name OPTIONAL ).

  ENDMETHOD.

  METHOD badi_definition.
    IF badi_spots_loaded = abap_false.
      SELECT * FROM badi_spot
        INTO TABLE @t_badi_spot.
      badi_spots_loaded = abap_true.
    ENDIF.

    rv_enhancement_spot = VALUE #( t_badi_spot[ KEY sorted_badi_name
                                                badi_name = iv_object_name ]-enhspotname OPTIONAL ).
  ENDMETHOD.

ENDCLASS.
