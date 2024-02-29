CLASS ycl_trm_compare_objects DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE .

  PUBLIC SECTION.

    TYPES:
      ty_t_request_keys TYPE STANDARD TABLE OF e071k WITH DEFAULT KEY .
    TYPES:
      BEGIN OF ty_s_objects,
        pgmid    TYPE string,
        object   TYPE string,
        obj_name TYPE string,
        objfunc  TYPE char01,
        activity TYPE string,
        keys     TYPE ty_t_request_keys,
      END OF ty_s_objects .
    TYPES:
      tyt_objects TYPE STANDARD TABLE OF ty_s_objects WITH DEFAULT KEY .

    TYPES: BEGIN OF ty_s_comparison.
             INCLUDE TYPE vrs_compare_item.
    TYPES:   objfunc      TYPE char01,
             activity     TYPE string,
             not_compared TYPE abap_bool,
             keys         TYPE ty_t_request_keys,
             lang         TYPE spras,
           END OF ty_s_comparison.
    TYPES: ty_t_comparison TYPE STANDARD TABLE OF ty_s_comparison WITH DEFAULT KEY .

    CLASS-METHODS create
      IMPORTING
        !iv_rfc_compare_destination TYPE rfcdest
      RETURNING
        VALUE(ro_as)                TYPE REF TO ycl_trm_compare_objects .
    METHODS compare
      IMPORTING
*        !it_objects          TYPE tyt_objects
        !it_objects          TYPE yif_trm_tr_object=>tab
      RETURNING
        VALUE(rt_comparison) TYPE ty_t_comparison
      RAISING
        ycx_trm_transport_request.
  PROTECTED SECTION.
  PRIVATE SECTION.

    DATA _rfc_compare_destination TYPE rfcdest.

    METHODS constructor
      IMPORTING
        iv_rfc_compare_destination TYPE rfcdest.

ENDCLASS.



CLASS ycl_trm_compare_objects IMPLEMENTATION.


  METHOD compare.

    " Code copied from SREPO ( SCREEN_0300_FORMS - FORM cal_data_0300 )

    DATA lt_compare_items TYPE vrs_compare_item_tab.
    DATA ls_compare_item  LIKE LINE OF lt_compare_items.
    DATA ls_rfcsi_a       TYPE rfcsi.
    DATA ls_rfcsi_b       TYPE rfcsi.
    DATA lt_nonvers       TYPE TABLE OF e071.
    DATA ls_nonvers       TYPE e071.
    DATA lv_result        TYPE trpari-s_checked.

*    DATA(lt_objects) = CORRESPONDING scwb_t_e071( it_objects ).

    DATA(lt_objects) = VALUE scwb_t_e071( FOR object IN it_objects
                                          (
                                            pgmid     = object->get_object_id(  )
                                            object    = object->get_object_type(  )
                                            obj_name  = object->get_object_name( )
                                            objfunc   = object->get_function(  )
                                            activity  = object->get_activity( )
                                           )
                                        ).

    " Quitamos los paquetes porque al comparar trae todos los objetos que contienen...
    DELETE lt_objects WHERE object = 'DEVC'.

    " Eliminamos las entradas de customizing para la comparación
    DELETE lt_objects WHERE objfunc = yif_trm_tr_object=>function-customizing.

    " Eliminamos las entradas marcadas como borradas para la comparación
    DELETE lt_objects WHERE objfunc = yif_trm_tr_object=>function-deleted.

    DATA lt_comparison TYPE vrs_compare_item_tab.
    DATA(lv_filter_lang) = abap_true.
    DATA(lv_delete_lang) = ' '.
    CALL FUNCTION 'SVRS_MASSCOMPARE_ACT_OBJECTS'
      EXPORTING
        it_e071                = lt_objects
*       IV_RFCDEST_A           =
        iv_rfcdest_b           = _rfc_compare_destination
        iv_filter_lang         = lv_filter_lang
        iv_delete_lang         = lv_delete_lang
*       IV_ABAP_IGNORE_CASE    = 'X'
*       IV_ABAP_CONDENSE       = 'X'
*       IV_ABAP_IGNORE_COMMENTS       = 'X'
*       IV_ABAP_EQUIVALENCE    = 'X'
        iv_with_gui_progress   = abap_false
        iv_ignore_report_text  = 'X'
      IMPORTING
        et_compare_items       = lt_comparison
        es_rfcsi_a             = ls_rfcsi_a
        es_rfcsi_b             = ls_rfcsi_b
        et_nonversionable_e071 = lt_nonvers
      EXCEPTIONS
        rfc_error              = 1
        not_supported          = 2
        OTHERS                 = 3.
    CASE sy-subrc.
      WHEN 0.
      WHEN 1.
        MESSAGE i008(tsys) WITH _rfc_compare_destination.
        RAISE EXCEPTION NEW ycx_trm_transport_request(  ).
      WHEN OTHERS.
        MESSAGE i015(tsys).
    ENDCASE.

    rt_comparison = CORRESPONDING #( lt_comparison ).

    " Delete duplicates
    SORT rt_comparison BY fragid fragment fragname pgmid object obj_name.
    DELETE ADJACENT DUPLICATES FROM rt_comparison COMPARING fragid fragment fragname pgmid object obj_name.

    " Add non versionable objects:
    LOOP AT lt_nonvers ASSIGNING FIELD-SYMBOL(<ls_nonvers>).

      " No meter duplicados
      IF line_exists( rt_comparison[ fragid = <ls_nonvers>-pgmid
                                     fragment = <ls_nonvers>-object
                                     fragname = <ls_nonvers>-obj_name
                                     pgmid = <ls_nonvers>-pgmid
                                     object = <ls_nonvers>-object
                                     obj_name = <ls_nonvers>-obj_name
                                     objfunc =  <ls_nonvers>-objfunc ] ).
        CONTINUE.
      ENDIF.

      INSERT VALUE #(
          fragid = <ls_nonvers>-pgmid
          fragment = <ls_nonvers>-object
          fragname = <ls_nonvers>-obj_name
          pgmid = <ls_nonvers>-pgmid
          object = <ls_nonvers>-object
          obj_name = <ls_nonvers>-obj_name
          objfunc =  <ls_nonvers>-objfunc
          not_compared = abap_true ) INTO TABLE rt_comparison.

    ENDLOOP.

    " The comparison only returns R3TR and LIMU objects... Others objects types must be added again
    DATA lr_objects_types_to_be_added TYPE RANGE OF ty_s_objects-pgmid.
    lr_objects_types_to_be_added = VALUE #(
      ( sign = 'I' option = 'EQ' low = 'DEVC' ) ).

    DATA lr_objects_id_to_be_added TYPE RANGE OF ty_s_objects-object.
    lr_objects_id_to_be_added = VALUE #(
      ( sign = 'I' option = 'EQ' low = 'LANG' ) ).

    LOOP AT it_objects ASSIGNING FIELD-SYMBOL(<lo_objects>).

      IF <lo_objects>->is_customizing( ).
        CONTINUE.
      ENDIF.

      IF <lo_objects>->get_object_type( ) NOT IN lr_objects_types_to_be_added AND
         <lo_objects>->get_object_id( ) NOT IN lr_objects_id_to_be_added.
        CONTINUE.
      ENDIF.

      " No meter duplicados
      IF line_exists( rt_comparison[ fragid    = <lo_objects>->get_object_id(  )
                                     fragment  = <lo_objects>->get_object_type(  )
                                     fragname  = <lo_objects>->get_object_name( )
                                     pgmid     = <lo_objects>->get_object_id(  )
                                     object    = <lo_objects>->get_object_type(  )
                                     obj_name  = <lo_objects>->get_object_name( )
                                     objfunc   = <lo_objects>->get_function( )
                                     lang      = <lo_objects>->get_language( )
                                     keys      = VALUE #( FOR key IN <lo_objects>->get_custo_entries(  )
                                        ( trkorr     = key->get_transport_request(  )->get_code(  )
                                          pgmid      = key->get_object_id( )
                                          object     = key->get_object_type( )
                                          objname    = key->get_object_name(  )
                                          as4pos     = key->get_position(  )
                                          mastertype = key->get_master_type( )
                                          mastername = key->get_master_name(  )
                                          viewname   = key->get_view_name( )
                                          tabkey     = key->get_tab_key(  )
                                          sortflag   = key->get_sort_flag( )
                                          flag       = key->get_flag( )
                                          lang       = key->get_language( )
                                          activity   = key->get_activity( )
                                        )
                                      ) ] ).
        CONTINUE.
      ENDIF.

      INSERT VALUE #(
          fragid    = <lo_objects>->get_object_id(  )
          fragment  = <lo_objects>->get_object_type(  )
          fragname  = <lo_objects>->get_object_name( )
          pgmid     = <lo_objects>->get_object_id(  )
          object    = <lo_objects>->get_object_type(  )
          obj_name  = <lo_objects>->get_object_name( )
          objfunc   = <lo_objects>->get_function( )
          lang      = <lo_objects>->get_language( )
          not_compared = abap_true
          keys      = VALUE #( FOR key IN <lo_objects>->get_custo_entries(  )
                                ( trkorr     = key->get_transport_request(  )->get_code(  )
                                  pgmid      = key->get_object_id( )
                                  object     = key->get_object_type( )
                                  objname    = key->get_object_name(  )
                                  as4pos     = key->get_position(  )
                                  mastertype = key->get_master_type( )
                                  mastername = key->get_master_name(  )
                                  viewname   = key->get_view_name( )
                                  tabkey     = key->get_tab_key(  )
                                  sortflag   = key->get_sort_flag( )
                                  flag       = key->get_flag( )
                                  lang       = key->get_language( )
                                  activity   = key->get_activity(  )
                                )
                              ) ) INTO TABLE rt_comparison.

    ENDLOOP.

    " Add entradas que se eliminan...
    DATA lr_objects_types_removed TYPE RANGE OF ty_s_objects-pgmid.
    lr_objects_types_removed = VALUE #(
      ( sign = 'I' option = 'EQ' low = 'LIMU' )
      ( sign = 'I' option = 'EQ' low = 'R3TR' ) ).

    LOOP AT it_objects ASSIGNING <lo_objects>.

      IF <lo_objects>->get_object_id(  ) NOT IN lr_objects_types_removed.
        CONTINUE.
      ENDIF.

      IF <lo_objects>->is_customizing(  ).
        CONTINUE.
      ENDIF.

      IF NOT <lo_objects>->is_deleted(  ).

          DATA(ls_e071) = VALUE e071( pgmid    = <lo_objects>->get_object_id(  )
                                      object   = <lo_objects>->get_object_type(  )
                                      obj_name = <lo_objects>->get_object_name( )
                                    ).

          " Los tipos L y T ya vienen en la comparación, el resto no
          CALL FUNCTION 'TR_CHECK_TYPE'
            EXPORTING
              wi_e071   = ls_e071
            IMPORTING
              pe_result = lv_result.

          IF lv_result = 'L' OR lv_result = 'T'.
            CONTINUE.
          ENDIF.

      ENDIF.

      " No meter duplicados
      IF line_exists( rt_comparison[ fragid     = <lo_objects>->get_object_id(  )
                                     fragment   = <lo_objects>->get_object_type(  )
                                     fragname   = <lo_objects>->get_object_name( )
                                     pgmid      = <lo_objects>->get_object_id(  )
                                     object     = <lo_objects>->get_object_type(  )
                                     obj_name   = <lo_objects>->get_object_name( )
                                     objfunc    = <lo_objects>->get_function( )
                                     lang      = <lo_objects>->get_language( )
                                     keys       = VALUE #( FOR key IN <lo_objects>->get_custo_entries(  )
                                                            ( trkorr     = key->get_transport_request(  )->get_code(  )
                                                              pgmid      = key->get_object_id( )
                                                              object     = key->get_object_type( )
                                                              objname    = key->get_object_name(  )
                                                              as4pos     = key->get_position(  )
                                                              mastertype = key->get_master_type( )
                                                              mastername = key->get_master_name(  )
                                                              viewname   = key->get_view_name( )
                                                              tabkey     = key->get_tab_key(  )
                                                              sortflag   = key->get_sort_flag( )
                                                              flag       = key->get_flag( )
                                                              lang       = key->get_language( )
                                                              activity   = key->get_activity(  )
                                                            )
                                                         )

                                    ] ).
        CONTINUE.
      ENDIF.

      INSERT VALUE #(
          fragid    = <lo_objects>->get_object_id(  )
          fragment  = <lo_objects>->get_object_type(  )
          fragname  = <lo_objects>->get_object_name( )
          pgmid     = <lo_objects>->get_object_id(  )
          object    = <lo_objects>->get_object_type(  )
          obj_name  = <lo_objects>->get_object_name( )
          objfunc   = <lo_objects>->get_function( )
          lang      = <lo_objects>->get_language( )
          keys      = VALUE #( FOR key IN <lo_objects>->get_custo_entries(  )
                                ( trkorr     = key->get_transport_request(  )->get_code(  )
                                  pgmid      = key->get_object_id( )
                                  object     = key->get_object_type( )
                                  objname    = key->get_object_name(  )
                                  as4pos     = key->get_position(  )
                                  mastertype = key->get_master_type( )
                                  mastername = key->get_master_name(  )
                                  viewname   = key->get_view_name( )
                                  tabkey     = key->get_tab_key(  )
                                  sortflag   = key->get_sort_flag( )
                                  flag       = key->get_flag( )
                                  lang       = key->get_language( )
                                  activity   = key->get_activity(  )
                                )
                              )
          not_compared = abap_true ) INTO TABLE rt_comparison.

    ENDLOOP.

    " Add entradas de customizing
    LOOP AT it_objects ASSIGNING <lo_objects> .
      "WHERE objfunc = 'K'.

      IF NOT <lo_objects>->is_customizing(  ).
        CONTINUE.
      ENDIF.

      " No meter duplicados
      ASSIGN rt_comparison[ fragid   = <lo_objects>->get_object_id(  )
                            fragment = <lo_objects>->get_object_type(  )
                            fragname = <lo_objects>->get_object_name( )
                            pgmid    = <lo_objects>->get_object_id(  )
                            object   = <lo_objects>->get_object_type(  )
                            obj_name = <lo_objects>->get_object_name( )
                            objfunc  = <lo_objects>->get_function( )
                            activity = <lo_objects>->get_activity( )
                            lang     = <lo_objects>->get_language( )
                           ] TO FIELD-SYMBOL(<ls_comparison>).
      IF sy-subrc = 0.
        INSERT LINES OF VALUE ty_t_request_keys(
                                FOR key IN <lo_objects>->get_custo_entries(  )
                                ( trkorr     = key->get_transport_request(  )->get_code(  )
                                  pgmid      = key->get_object_id( )
                                  object     = key->get_object_type( )
                                  objname    = key->get_object_name(  )
                                  as4pos     = key->get_position(  )
                                  mastertype = key->get_master_type( )
                                  mastername = key->get_master_name(  )
                                  viewname   = key->get_view_name( )
                                  tabkey     = key->get_tab_key(  )
                                  sortflag   = key->get_sort_flag( )
                                  flag       = key->get_flag( )
                                  lang       = key->get_language( )
                                  activity   = key->get_activity(  )
                                )
                              )
          INTO TABLE <ls_comparison>-keys.
        CONTINUE.
      ENDIF.

      INSERT VALUE #(
          fragid    = <lo_objects>->get_object_id(  )
          fragment  = <lo_objects>->get_object_type(  )
          fragname  = <lo_objects>->get_object_name( )
          pgmid     = <lo_objects>->get_object_id(  )
          object    = <lo_objects>->get_object_type(  )
          obj_name  = <lo_objects>->get_object_name( )
          objfunc   = <lo_objects>->get_function( )
          lang      = <lo_objects>->get_language( )
          keys      = VALUE #( FOR key IN <lo_objects>->get_custo_entries(  )
                                ( trkorr     = key->get_transport_request(  )->get_code(  )
                                  pgmid      = key->get_object_id( )
                                  object     = key->get_object_type( )
                                  objname    = key->get_object_name(  )
                                  as4pos     = key->get_position(  )
                                  mastertype = key->get_master_type( )
                                  mastername = key->get_master_name(  )
                                  viewname   = key->get_view_name( )
                                  tabkey     = key->get_tab_key(  )
                                  sortflag   = key->get_sort_flag( )
                                  flag       = key->get_flag( )
                                  lang       = key->get_language( )
                                  activity   = key->get_activity(  )
                                )
                             )
          activity  = <lo_objects>->get_activity( )
          not_compared = abap_true ) INTO TABLE rt_comparison.

    ENDLOOP.

  ENDMETHOD.


  METHOD constructor.
    _rfc_compare_destination = iv_rfc_compare_destination.
  ENDMETHOD.


  METHOD create.
    ro_as = NEW ycl_trm_compare_objects( iv_rfc_compare_destination ).
  ENDMETHOD.
ENDCLASS.
