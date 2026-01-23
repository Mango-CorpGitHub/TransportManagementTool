CLASS ycl_trm_cross_ref_describe_obj DEFINITION
  PUBLIC FINAL
  CREATE PRIVATE
  GLOBAL FRIENDS ycl_trm_cross_ref.

  PUBLIC SECTION.
    TYPES: BEGIN OF ty_s_object,
             object_pgmid TYPE pgmid,
             object_type  TYPE trobjtype,
             object_name  TYPE trobj_name,
           END OF ty_s_object.

    TYPES: BEGIN OF ty_s_method_desription,
             defined_in TYPE ty_s_object,
             exceptions TYPE STANDARD TABLE OF vseoexcep WITH DEFAULT KEY,
             parameters TYPE TABLE OF vseoparam WITH DEFAULT KEY,
           END OF ty_s_method_desription.

    TYPES: BEGIN OF ty_s_tabd_desription,
             fields TYPE STANDARD TABLE OF dd03v WITH DEFAULT KEY,
           END OF ty_s_tabd_desription.

    TYPES: BEGIN OF ty_s_ddls_desription,
             fields TYPE ytrm_t_ddl_base_fields,
           END OF ty_s_ddls_desription.

    TYPES: BEGIN OF ty_s_desription,
             object_pgmid          TYPE pgmid,
             object_type           TYPE trobjtype,
             object_name           TYPE trobj_name,
             sub_object_type       TYPE trobjtype,
             sub_object_name       TYPE trobj_name,
             sub_object_name_alias TYPE trobj_name,
             method_description    TYPE ty_s_method_desription,
             source_code           TYPE string,
           END OF ty_s_desription.
    TYPES ty_t_description TYPE STANDARD TABLE OF ty_s_desription WITH DEFAULT KEY.

    METHODS describe
      IMPORTING iv_object_name        TYPE vrsd-objname
      RETURNING VALUE(rt_description) TYPE ty_t_description
      RAISING   ycx_trm_transport_request.

    METHODS method
      IMPORTING iv_object_name               TYPE string
                iv_method_name               TYPE string OPTIONAL
      RETURNING VALUE(rs_method_description) TYPE ty_s_method_desription
      RAISING   ycx_trm_transport_request.

    METHODS tabd
      IMPORTING iv_object_name        TYPE vrsd-objname
      RETURNING VALUE(rs_description) TYPE ty_s_tabd_desription.

    METHODS ddls
      IMPORTING iv_object_name        TYPE vrsd-objname
      RETURNING VALUE(rs_description) TYPE ty_s_ddls_desription.

    METHODS public
      IMPORTING iv_object_name        TYPE vrsd-objname
      RETURNING VALUE(rt_description) TYPE ty_t_description
      RAISING   ycx_trm_transport_request.

    METHODS protected
      IMPORTING iv_object_name        TYPE vrsd-objname
      RETURNING VALUE(rt_description) TYPE ty_t_description
      RAISING   ycx_trm_transport_request.

    METHODS private
      IMPORTING iv_object_name        TYPE vrsd-objname
      RETURNING VALUE(rt_description) TYPE ty_t_description
      RAISING   ycx_trm_transport_request.

    METHODS find_in_cache
      IMPORTING iv_object_name        TYPE vrsd-objname
      RETURNING VALUE(rt_description) TYPE ty_t_description
      RAISING   cx_sy_itab_line_not_found.

    METHODS save_in_cache
      IMPORTING iv_object_name TYPE vrsd-objname
                it_description TYPE ty_t_description.

    CLASS-METHODS free_cache.

  PRIVATE SECTION.
    TYPES ty_t_seoaliases TYPE STANDARD TABLE OF seoaliases WITH DEFAULT KEY.

    TYPES: BEGIN OF ty_s_describe_cache,
             object_name     TYPE vrsd-objname,
             rfc_destination TYPE rfcdes-rfcdest,
             description     TYPE ty_t_description,
           END OF ty_s_describe_cache,
           ty_t_describe_cache TYPE STANDARD TABLE OF ty_s_describe_cache WITH NON-UNIQUE KEY object_name.

    DATA rfc_destination TYPE rfcdes-rfcdest.

    CONSTANTS: BEGIN OF c_cpub_cpro_cpri,
                 cpub TYPE string VALUE 'CPUB',
                 cpro TYPE string VALUE 'CPRO',
                 cpri TYPE string VALUE 'CPRI',
               END OF c_cpub_cpro_cpri.

    CLASS-DATA t_describe_cache TYPE ty_t_describe_cache.

    CLASS-METHODS new
      IMPORTING iv_rfc_comparison  TYPE rfcdes-rfcdest DEFAULT 'NONE'
      RETURNING VALUE(ro_instance) TYPE REF TO ycl_trm_cross_ref_describe_obj.

    METHODS constructor
      IMPORTING iv_rfc_comparison TYPE rfcdes-rfcdest.

    METHODS add_from_alias
      IMPORTING it_aliases            TYPE ty_t_seoaliases
      RETURNING VALUE(rt_description) TYPE ty_t_description.

    METHODS class
      IMPORTING iv_object_name        TYPE vrsd-objname
      RETURNING VALUE(rt_description) TYPE ty_t_description
      RAISING   ycx_trm_transport_request.

    METHODS interface
      IMPORTING iv_object_name        TYPE vrsd-objname
      RETURNING VALUE(rt_description) TYPE ty_t_description
      RAISING   ycx_trm_transport_request.

    METHODS cpub_cpro_cpri
      IMPORTING iv_object_name        TYPE vrsd-objname
                iv_cpub_cpro_cpri     TYPE string
      RETURNING VALUE(rt_description) TYPE ty_t_description
      RAISING   ycx_trm_transport_request.

ENDCLASS.


CLASS ycl_trm_cross_ref_describe_obj IMPLEMENTATION.

  METHOD constructor.
    rfc_destination = iv_rfc_comparison.
    IF rfc_destination = 'NONE'.
      CLEAR rfc_destination.
    ENDIF.
  ENDMETHOD.

  METHOD new.
    RETURN NEW #( iv_rfc_comparison ).
  ENDMETHOD.

  METHOD describe.
    TRY.
        RETURN find_in_cache( iv_object_name  ).
      CATCH cx_sy_itab_line_not_found.
    ENDTRY.

    SELECT SINGLE object FROM tadir
      WHERE obj_name = @iv_object_name
      INTO @DATA(lv_object_type).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    CASE lv_object_type.

      WHEN 'CLAS'.
        DATA(lt_description) = class( iv_object_name ).

      WHEN 'INTF'.
        lt_description = interface( iv_object_name ).

      WHEN OTHERS.
        RETURN.
    ENDCASE.

    " Save cache
    save_in_cache( iv_object_name = iv_object_name
                   it_description = lt_description ).

    RETURN lt_description.
  ENDMETHOD.

  METHOD interface.
    DATA lv_object_name   TYPE vrsd-objname.
    DATA lt_vsmodisrc     TYPE STANDARD TABLE OF smodisrc.
    DATA lt_pseoaliases   TYPE STANDARD TABLE OF seoaliases.
    DATA lt_dpvseoattrib  TYPE STANDARD TABLE OF vseoattrib_vrs.
    DATA lt_dpvseocompri  TYPE STANDARD TABLE OF vseocompri.
    DATA lt_dpvseoevent   TYPE STANDARD TABLE OF vseoevent.
    DATA lt_dpvseoexcep   TYPE STANDARD TABLE OF vseoexcep.
    DATA lt_dpvseointerf  TYPE STANDARD TABLE OF vseointerf.
    DATA lt_dpsmodilog    TYPE STANDARD TABLE OF smodilog.
    DATA lt_dpvseomethod  TYPE STANDARD TABLE OF vseomethod.
    DATA lt_dpvseoparam   TYPE STANDARD TABLE OF vseoparam.
    DATA lt_dppool_source TYPE STANDARD TABLE OF abaptxt255.
    DATA lt_dpsource      TYPE STANDARD TABLE OF abaptxt255.
    DATA lt_dptrdir       TYPE STANDARD TABLE OF trdir.
    DATA lt_dtype_tab     TYPE STANDARD TABLE OF vseotype_vrs.
    DATA lt_dpseotypepls  TYPE STANDARD TABLE OF seotypepls.

    lv_object_name = iv_object_name.

    CALL FUNCTION 'SVRS_GET_VERSION_INTF_40'
      EXPORTING  destination           = rfc_destination
                 object_name           = iv_object_name
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
      RAISE EXCEPTION NEW ycx_trm_transport_request( logger = lo_log ).
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
                                source_code     = ls_seoattrib-type ) ).

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
      RAISE EXCEPTION NEW ycx_trm_transport_request( logger = lo_log ).
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

    rt_description = VALUE #( BASE rt_description FOR ls_cpub_description IN public( iv_object_name )
                              ( ls_cpub_description ) ).
    rt_description = VALUE #( BASE rt_description FOR ls_cpro_description IN protected( iv_object_name )
                              ( ls_cpro_description ) ).
    rt_description = VALUE #( BASE rt_description FOR ls_cpri_description IN private( iv_object_name )
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
        CATCH ycx_trm_transport_request.
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

  METHOD method.
    DATA(lt_object_descr) = describe( CONV #( iv_object_name ) ).

    TRY.
        rs_method_description = lt_object_descr[ sub_object_type = 'METH'
                                                 sub_object_name = iv_method_name ]-method_description.

      CATCH cx_sy_itab_line_not_found.

        TRY.

            rs_method_description = lt_object_descr[ sub_object_type       = 'METH'
                                                     sub_object_name_alias = iv_method_name ]-method_description.

          CATCH cx_sy_itab_line_not_found.
            DATA(lo_log) = ycl_trm_logger=>new( ).
            MESSAGE e018(ytrm) WITH iv_method_name rfc_destination INTO DATA(lv_dummy) ##NEEDED.
            lo_log->add_message( CORRESPONDING #( sy ) ).
            RAISE EXCEPTION NEW ycx_trm_transport_request( logger = lo_log ).

        ENDTRY.

    ENDTRY.
  ENDMETHOD.

  METHOD tabd.
    DATA lv_object_name TYPE vrsd-objname.

    lv_object_name = iv_object_name.

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
  ENDMETHOD.

  METHOD ddls.
    DATA lv_object_name TYPE vrsd-objname.

    lv_object_name = iv_object_name.

    DATA(lv_rfc_destination) = rfc_destination.
    IF lv_rfc_destination IS INITIAL.
      lv_rfc_destination = 'NONE'.
    ENDIF.

    CALL FUNCTION 'YTRM_FM_CROSS_REF_DESCR_DDLS' DESTINATION lv_rfc_destination
      EXPORTING ddlname = lv_object_name
      TABLES    fields  = rs_description-fields.

  ENDMETHOD.

  METHOD free_cache.
    CLEAR t_describe_cache.
  ENDMETHOD.

  METHOD private.
    RETURN cpub_cpro_cpri( iv_cpub_cpro_cpri = c_cpub_cpro_cpri-cpri
                           iv_object_name    = iv_object_name ).
  ENDMETHOD.

  METHOD protected.
    RETURN cpub_cpro_cpri( iv_cpub_cpro_cpri = c_cpub_cpro_cpri-cpro
                           iv_object_name    = iv_object_name ).
  ENDMETHOD.

  METHOD public.
    RETURN cpub_cpro_cpri( iv_cpub_cpro_cpri = c_cpub_cpro_cpri-cpub
                           iv_object_name    = iv_object_name ).
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
    RETURN t_describe_cache[ object_name     = iv_object_name
                             rfc_destination = rfc_destination ]-description.
  ENDMETHOD.

  METHOD save_in_cache.
    INSERT VALUE #( object_name     = iv_object_name
                    rfc_destination = rfc_destination
                    description     = it_description ) INTO TABLE t_describe_cache.
  ENDMETHOD.

ENDCLASS.
