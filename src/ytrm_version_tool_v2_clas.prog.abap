*&---------------------------------------------------------------------*
*& Include          yTRM_VERSION_TOOL_V2_CLAS
*&---------------------------------------------------------------------*

CLASS lcl_utils DEFINITION.

  PUBLIC SECTION.

    CLASS-METHODS navigate_to_request
      IMPORTING
        iv_request TYPE e070-trkorr.

    CLASS-METHODS open_on_browser
      IMPORTING
        iv_request_description TYPE string.

ENDCLASS.

CLASS lcl_utils IMPLEMENTATION.

  METHOD navigate_to_request.

    DATA: ls_rseumod     TYPE rseumod,
          ls_old_rseumod TYPE rseumod.

    CALL FUNCTION 'RS_WORKBENCH_CUSTOMIZING'
      EXPORTING
        suppress_dialog = 'X'
      IMPORTING
        setting         = ls_old_rseumod.
    ls_rseumod = ls_old_rseumod.
    ls_rseumod-wbo_screen = '7'.

    UPDATE rseumod FROM ls_rseumod.

    DATA(lt_param) = VALUE rfc_t_spagpa( ( parid = 'KOR' parval = iv_request ) ).

    CALL FUNCTION 'ABAP4_CALL_TRANSACTION' STARTING NEW TASK 'TEST'
      EXPORTING
        tcode       = 'SE01'
        skip_screen = 'X'
      TABLES
        spagpa_tab  = lt_param.

  ENDMETHOD.

  METHOD open_on_browser.
*    Enhance to navigate to external documentation reference

*    CALL METHOD cl_gui_frontend_services=>execute
*      EXPORTING
*        document = lv_url_ses
*      EXCEPTIONS
*        OTHERS   = 1.

    MESSAGE 'Enhance to navigate to external documentation reference' TYPE 'I'.

  ENDMETHOD.

ENDCLASS.

CLASS lcl_sh_for_transport_request DEFINITION.

  PUBLIC SECTION.

    TYPES ty_r_users TYPE RANGE OF sy-uname.
    TYPES ty_t_selected_values TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

    METHODS show
      IMPORTING
                ir_user                  TYPE ty_r_users
      RETURNING VALUE(rt_selected_value) TYPE ty_t_selected_values.

ENDCLASS.

CLASS lcl_sh_for_transport_request IMPLEMENTATION.

  METHOD show.

    TYPES:
      BEGIN OF ltyp_sel_orders,
        trkorr     TYPE e070-trkorr,
        as4text    TYPE e07t-as4text,
        trfunction TYPE e070-trfunction,
        as4user    TYPE e070-as4user,
        as4date    TYPE e070-as4date,
        as4time    TYPE e070-as4time,
      END OF ltyp_sel_orders.

    DATA lt_sel_orders TYPE TABLE OF ltyp_sel_orders.
    DATA lt_return     TYPE TABLE OF ddshretval.

    DATA(ls_query_by_attr) = VALUE yif_trm_transport_request_db=>typ_s_tr_query_by_attr(
                                                                                 parentid = VALUE #( ( sign = 'I' option = 'EQ' low = space ) )
                                                                                 status   = VALUE #(
                                                                                                     ( sign = 'I' option = 'EQ' low = yif_trm_transport_request=>status-modifiable  )
                                                                                                     ( sign = 'I' option = 'EQ' low = yif_trm_transport_request=>status-modifiable_protected )
                                                                                                   )
                                                                                 owner    = VALUE #( ( sign = 'I' option = 'EQ' low = sy-uname ) )
                                                                               ).

    TRY.
        DATA(lt_transport_request) = ycl_trm_transport_request=>get_by_attributes( im_s_query_by_attr = ls_query_by_attr ).
      CATCH ycx_trm_transport_request.
        RETURN.
    ENDTRY.

    lt_sel_orders = VALUE #( FOR transport_request IN lt_transport_request ( trkorr     = transport_request->get_code(  )
                                                                             as4text    = transport_request->get_description(  )
                                                                             trfunction = transport_request->get_type(  )
                                                                             as4user    = transport_request->get_owner(  )
                                                                             as4date    = transport_request->get_last_change_date(  )
                                                                             as4time    = transport_request->get_last_change_time( )
                                                                             )
                            ).

    SORT lt_sel_orders BY as4date DESCENDING as4time DESCENDING.
    CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
      EXPORTING
        retfield        = 'TRKORR'
        window_title    = CONV char50( |Select Order| )
        value_org       = 'S'
        multiple_choice = abap_true
      TABLES
        value_tab       = lt_sel_orders
        return_tab      = lt_return
      EXCEPTIONS
        parameter_error = 1
        no_values_found = 2
        OTHERS          = 3.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    rt_selected_value = VALUE #( FOR ls_return IN lt_return ( CONV #( ls_return-fieldval ) ) ).

  ENDMETHOD.

ENDCLASS.

CLASS lcl_alv_qry DEFINITION.

  PUBLIC SECTION.

    TYPES ty_r_trkorr TYPE RANGE OF e070-trkorr.
    TYPES ty_t_request_keys TYPE STANDARD TABLE OF e071k WITH DEFAULT KEY.

    TYPES: BEGIN OF ty_s_alv_output,
             fragid          TYPE pgmid,
             fragment        TYPE trobjtype,
             fragname        TYPE trobj_name,
             pgmid           TYPE pgmid,
             object          TYPE trobjtype,
             obj_name        TYPE trobj_name,
             collisions      TYPE STANDARD TABLE OF e070-trkorr WITH DEFAULT KEY,
             has_collisions  TYPE icon-name,
             its_new         TYPE icon-name,
             its_equal       TYPE icon-name,
             its_customizing TYPE icon-name,
             objfunc         TYPE objfunc,
             keys            TYPE ty_t_request_keys,
             activity        TYPE tractivity,
             cell_style      TYPE salv_t_int4_column,
             not_compared    TYPE abap_bool,
             lang            TYPE spras,
           END OF ty_s_alv_output,
           ty_t_alv_output TYPE STANDARD TABLE OF ty_s_alv_output WITH DEFAULT KEY.

    DATA result TYPE ty_t_alv_output READ-ONLY.

    METHODS execute
      IMPORTING
        iv_rfc_compare_destination TYPE rfcdest
        iv_compare                 TYPE abap_bool
        ir_transport_request       TYPE ty_r_trkorr
        it_transport_request       TYPE yif_trm_transport_request=>tab.

ENDCLASS.

CLASS lcl_alv_qry IMPLEMENTATION.

  METHOD execute.

    DATA(lt_tr_objects) = VALUE yif_trm_tr_object=>tab( ).

    lt_tr_objects = VALUE #( BASE lt_tr_objects
                             FOR lo_transport_request IN it_transport_request
                             FOR entry IN lo_transport_request->get_entries( im_include_task_objects = abap_true )
                                    ( entry )
                           ).

    IF iv_compare EQ abap_true.

      DATA(lt_comparasion) = ycl_trm_compare_objects=>create( iv_rfc_compare_destination )->compare( lt_tr_objects ).

      DATA(lt_fragments_and_objects) = VALUE ycl_trm_get_objects_w_colision=>tyt_objects(
        FOR ls_comparison IN lt_comparasion
        ( pgmid = ls_comparison-pgmid
          object =  ls_comparison-object
          obj_name = ls_comparison-obj_name  ) ).

      lt_fragments_and_objects = VALUE ycl_trm_get_objects_w_colision=>tyt_objects(
        BASE lt_fragments_and_objects
        FOR ls_comparison IN lt_comparasion
        ( pgmid = ls_comparison-fragid
          object =  ls_comparison-fragment
          obj_name = ls_comparison-fragname ) ).

      result = CORRESPONDING #( lt_comparasion MAPPING its_equal    = equal
                                                       its_new      = not_comparable
                                                       not_compared = not_compared ).

    ELSE.

      lt_fragments_and_objects = VALUE ycl_trm_get_objects_w_colision=>tyt_objects( FOR lo_tr_objects IN lt_tr_objects
                                                                                         ( pgmid    = lo_tr_objects->get_object_id( )
                                                                                           object   = lo_tr_objects->get_object_type( )
                                                                                           obj_name = lo_tr_objects->get_object_name( )
                                                                                         )
                                                                                   ).

      result = VALUE #( FOR object IN lt_tr_objects
                         (
                           pgmid     = object->get_object_id( )
                           object    = object->get_object_type( )
                           obj_name  = object->get_object_name( )
                           objfunc   = object->get_function( )
                           activity  = object->get_activity( )
                           lang      = object->get_language( )
                          )
                       ).

    ENDIF.

    SORT lt_fragments_and_objects BY pgmid object obj_name.
    DELETE ADJACENT DUPLICATES FROM lt_fragments_and_objects.

    DATA(lt_objects_with_colision) = ycl_trm_get_objects_w_colision=>create( )->find(
      it_objects_being_transported = CORRESPONDING #( lt_fragments_and_objects )
      ir_tr_being_transported = CORRESPONDING #( ir_transport_request ) ).

    LOOP AT lt_objects_with_colision ASSIGNING FIELD-SYMBOL(<ls_objects_with_colision>).

      ASSIGN result[ fragid   = <ls_objects_with_colision>-pgmid
                     fragment = <ls_objects_with_colision>-object
                     fragname = <ls_objects_with_colision>-obj_name ] TO FIELD-SYMBOL(<ls_alv_output>).
      IF sy-subrc = 0.
        INSERT CONV #( <ls_objects_with_colision>-request ) INTO TABLE <ls_alv_output>-collisions.
        <ls_alv_output>-has_collisions = icon_led_red.
        CONTINUE.
      ENDIF.

      " Find collisions to all object, not only fragment
      LOOP AT result ASSIGNING <ls_alv_output> WHERE pgmid    = <ls_objects_with_colision>-pgmid AND
                                                     object   = <ls_objects_with_colision>-object AND
                                                     obj_name = <ls_objects_with_colision>-obj_name.

        INSERT CONV #( <ls_objects_with_colision>-request ) INTO TABLE <ls_alv_output>-collisions.
        <ls_alv_output>-has_collisions = icon_led_red.
      ENDLOOP.

    ENDLOOP.

    LOOP AT result ASSIGNING <ls_alv_output>.

      IF <ls_alv_output>-has_collisions IS INITIAL.
        <ls_alv_output>-has_collisions = icon_led_green.
      ENDIF.

      IF <ls_alv_output>-its_equal = abap_true.
        <ls_alv_output>-its_equal = icon_checked.
      ENDIF.

      IF <ls_alv_output>-its_new = abap_true.
        <ls_alv_output>-its_new = icon_checked.
      ENDIF.

      IF <ls_alv_output>-not_compared = abap_true.
        <ls_alv_output>-its_new = icon_question.
        <ls_alv_output>-its_equal = icon_question.
      ENDIF.

      IF <ls_alv_output>-objfunc = yif_trm_tr_object=>function-customizing.
        <ls_alv_output>-its_customizing = icon_foreign_key.
      ENDIF.

      IF <ls_alv_output>-objfunc = yif_trm_tr_object=>function-deleted.
        <ls_alv_output>-its_customizing = icon_delete.
      ENDIF.

      <ls_alv_output>-cell_style = COND #( WHEN <ls_alv_output>-objfunc = yif_trm_tr_object=>function-customizing
                                             OR <ls_alv_output>-objfunc = yif_trm_tr_object=>function-deleted
                                           THEN VALUE #( ( columnname = 'ITS_CUSTOMIZING' value = if_salv_c_cell_type=>button ) ) ).

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.

CLASS lcl_selected_transport_request DEFINITION CREATE PRIVATE.

  PUBLIC SECTION.

    TYPES: ty_r_transport_request TYPE RANGE OF e070-trkorr.

    CLASS-METHODS create
      RETURNING VALUE(ro_selected_tr) TYPE REF TO lcl_selected_transport_request.

    METHODS display
      IMPORTING it_selected_tr TYPE yif_trm_transport_request=>tab.

  PRIVATE SECTION.

    TYPES: BEGIN OF ty_s_request_data,
             request     TYPE e070-trkorr,
             type        TYPE string,
             description TYPE e07t-as4text,
             user        TYPE e070-as4user,
             user_name   TYPE user_addr-name_textc,
           END OF ty_s_request_data,
           ty_t_request_data TYPE STANDARD TABLE OF ty_s_request_data WITH DEFAULT KEY.

    DATA gt_request_data TYPE ty_t_request_data.

    METHODS on_link_click FOR EVENT link_click OF cl_salv_events_table
      IMPORTING row column.

ENDCLASS.

CLASS lcl_selected_transport_request IMPLEMENTATION.

  METHOD create.
    ro_selected_tr = NEW lcl_selected_transport_request(  ).
  ENDMETHOD.


  METHOD display.

    DATA(lv_name) = VALUE ad_namtext(  ).

    gt_request_data = VALUE ty_t_request_data( FOR lo_request_complete_data IN it_selected_tr
      ( request     = lo_request_complete_data->get_code(  )
        type        = COND #( WHEN lo_request_complete_data->is_task( )
                              THEN 'Task'
                              ELSE 'Request'
                            )
        description = lo_request_complete_data->get_description(  )
        user        = lo_request_complete_data->get_owner(
                        IMPORTING
                          ex_name = lv_name
                      )
        user_name   = lv_name
       ) ).

    IF lines( gt_request_data ) = 0.
      MESSAGE 'No transport request selected' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    cl_salv_table=>factory(
      IMPORTING
        r_salv_table = DATA(alv_popup)
      CHANGING
        t_table      = gt_request_data ).

    alv_popup->set_screen_popup(
          start_column = 1
          end_column   = 75
          start_line   = 1
          end_line     = 10 ).

    CAST cl_salv_column_table( alv_popup->get_columns( )->get_column( 'TYPE' ) )->set_short_text( CONV #( 'Type' ) ).
    CAST cl_salv_column_table( alv_popup->get_columns( )->get_column( 'TYPE' ) )->set_medium_text( CONV #( 'Type' ) ).
    CAST cl_salv_column_table( alv_popup->get_columns( )->get_column( 'TYPE' ) )->set_long_text( CONV #( 'Type' ) ).
    IF NOT line_exists( gt_request_data[ type = 'Task' ] ).

      CAST cl_salv_column_table( alv_popup->get_columns( )->get_column( 'TYPE' ) )->set_visible( abap_false ).

    ENDIF.

    CAST cl_salv_column_table( alv_popup->get_columns( )->get_column( 'REQUEST' ) )->set_key( abap_true ).
    CAST cl_salv_column_table( alv_popup->get_columns( )->get_column( 'REQUEST' ) )->set_cell_type( if_salv_c_cell_type=>hotspot ).
    CAST cl_salv_column_table( alv_popup->get_columns( )->get_column( 'REQUEST' ) )->set_tooltip( 'Navigate to Transport Request' ).

    CAST cl_salv_column_table( alv_popup->get_columns( )->get_column( 'DESCRIPTION' ) )->set_key( abap_true ).
    CAST cl_salv_column_table( alv_popup->get_columns( )->get_column( 'DESCRIPTION' ) )->set_cell_type( if_salv_c_cell_type=>hotspot ).
    CAST cl_salv_column_table( alv_popup->get_columns( )->get_column( 'DESCRIPTION' ) )->set_tooltip( 'Navigate to SES' ).

    alv_popup->get_functions( )->set_all( abap_true ).
    alv_popup->get_columns( )->set_optimize( abap_true ).
    alv_popup->get_selections( )->set_selection_mode( if_salv_c_selection_mode=>multiple ).

    CAST cl_salv_column_table( alv_popup->get_columns( )->get_column( 'USER_NAME' ) )->set_short_text( CONV #( 'Owner name' ) ).
    CAST cl_salv_column_table( alv_popup->get_columns( )->get_column( 'USER_NAME' ) )->set_medium_text( CONV #( 'Owner name' ) ).
    CAST cl_salv_column_table( alv_popup->get_columns( )->get_column( 'USER_NAME' ) )->set_long_text( CONV #( 'Owner name' ) ).

    CAST cl_salv_column_table( alv_popup->get_columns( )->get_column( 'USER' ) )->set_f4( abap_false ).

    alv_popup->get_display_settings( )->set_list_header( |Selected Transport Requests : { lines( gt_request_data ) }| ).

    DATA(lr_events) = alv_popup->get_event( ).
    SET HANDLER on_link_click FOR lr_events.

    alv_popup->display( ).

  ENDMETHOD.

  METHOD on_link_click.
    CASE column.

      WHEN 'REQUEST'.
        lcl_utils=>navigate_to_request( gt_request_data[ row ]-request ).

      WHEN 'DESCRIPTION'.
        lcl_utils=>open_on_browser( CONV #( gt_request_data[ row ]-description ) ).

    ENDCASE.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_app DEFINITION.

  PUBLIC SECTION.

    TYPES ty_r_trkorr TYPE RANGE OF e070-trkorr.

    METHODS run
      IMPORTING
        iv_user_request            TYPE sy-uname
        iv_rfc_compare_destination TYPE rfcdest
        iv_compare                 TYPE abap_bool
        iv_tr_descr                TYPE e07t-as4text
        ir_transport_request       TYPE ty_r_trkorr
        it_transport_request       TYPE yif_trm_transport_request=>tab.
    METHODS constructor
      IMPORTING
        ir_alv_qry TYPE REF TO lcl_alv_qry.

    METHODS on_user_command
      FOR EVENT added_function OF cl_salv_events
      IMPORTING !e_salv_function .

    METHODS on_user_command_collisions
      FOR EVENT added_function OF cl_salv_events
      IMPORTING !e_salv_function .

    METHODS on_click
      FOR EVENT link_click OF cl_salv_events_table
      IMPORTING
        row
        column.

    METHODS on_double_click
      FOR EVENT double_click OF cl_salv_events_table
      IMPORTING
        row
        column.

    METHODS on_click_collisions
      FOR EVENT link_click OF cl_salv_events_table
      IMPORTING
        row
        column.

  PRIVATE SECTION.

    TYPES: BEGIN OF ty_s_collisions_output,
             request     TYPE e070-trkorr,
             description TYPE e07t-as4text,
             user        TYPE e070-as4user,
             user_name   TYPE user_addr-name_textc,
           END OF ty_s_collisions_output,
           ty_t_collisions_output TYPE STANDARD TABLE OF ty_s_collisions_output WITH DEFAULT KEY.

    TYPES: BEGIN OF ty_s_alv_output.
             INCLUDE TYPE lcl_alv_qry=>ty_s_alv_output.
    TYPES:   checkbox TYPE abap_bool,
           END OF ty_s_alv_output,
           ty_t_alv_output TYPE STANDARD TABLE OF ty_s_alv_output WITH DEFAULT KEY.

    DATA alv_output TYPE ty_t_alv_output.
    DATA alv_output_full TYPE ty_t_alv_output.
    DATA total_collisions   TYPE i.
    DATA alv_collisions_output TYPE ty_t_collisions_output.

    DATA alv TYPE REF TO cl_salv_table.
    DATA alv_collisions TYPE REF TO cl_salv_table.
    DATA g_container_up TYPE REF TO cl_gui_container.
    DATA g_container_down TYPE REF TO cl_gui_container.
    DATA alv_qry TYPE REF TO lcl_alv_qry.
    DATA r_transport_request TYPE ty_r_trkorr.
    DATA rfc_compare_destination TYPE rfcdest.
    DATA tr_descr                TYPE e07t-as4text.
    DATA ai_compare              TYPE abap_bool.
    DATA at_transport_request    TYPE yif_trm_transport_request=>tab.

    METHODS _display_collisions_alv
      IMPORTING
        it_collisions TYPE ty_t_collisions_output
      RAISING
        cx_salv_msg
        cx_salv_no_new_data_allowed.

    METHODS _find_all_collisions
      RETURNING VALUE(rt_collisions) TYPE ty_t_collisions_output.

    METHODS _find_selected_obj_collisions
      RETURNING VALUE(rt_collisions) TYPE ty_t_collisions_output.

    METHODS _find_selected_tr_collisions
      RETURNING VALUE(rt_collisions) TYPE ty_t_alv_output.

    METHODS _find_data
      IMPORTING
                iv_rfc_compare_destination TYPE rfcdest
                ir_transport_request       TYPE ty_r_trkorr
                it_transport_request       TYPE yif_trm_transport_request=>tab
      RETURNING VALUE(rt_result)           TYPE ty_t_alv_output.

    METHODS _display_main_alv
      IMPORTING it_objects TYPE ty_t_alv_output OPTIONAL
      RAISING
                cx_salv_existing
                cx_salv_msg
                cx_salv_wrong_call.

    METHODS _set_comparation_mode.

    METHODS _compare_to_destination_system.
    METHODS _condense
      IMPORTING
        ir_transport_request        TYPE ty_r_trkorr
      RETURNING
        VALUE(rr_transport_request) TYPE ty_r_trkorr.
    METHODS _release_transport_requests
      IMPORTING
        io_log TYPE REF TO yif_trm_logger.
    METHODS _alv_add_exclusive_quality.
    METHODS _alv_add_exclusive_productive.
    METHODS _create_and_release_toc
      IMPORTING
        io_log TYPE REF TO yif_trm_logger.
    METHODS _select_all
      IMPORTING
        im_click TYPE abap_bool.

    METHODS _confirmation_popup
      EXPORTING
        ex_releasing      TYPE xfeld
        ex_description    TYPE as4text
        ex_go_to_stms     TYPE xfeld
      RETURNING
        VALUE(re_confirm) TYPE sychar01.

    METHODS _set_app_title.

    METHODS _prepare_alv
      RAISING
        cx_salv_data_error
        cx_salv_existing
        cx_salv_not_found
        cx_salv_wrong_call.

    METHODS _compare
      RAISING
        cx_salv_data_error
        cx_salv_existing
        cx_salv_not_found
        cx_salv_wrong_call.

    METHODS _on_click_on_checkbox
      IMPORTING
                is_alv_output        TYPE lcl_app=>ty_s_alv_output
      RETURNING VALUE(rs_alv_output) TYPE lcl_app=>ty_s_alv_output.

    METHODS _on_click_on_its_customizing
      IMPORTING
        is_alv_output TYPE lcl_app=>ty_s_alv_output.

    METHODS _on_click_on_object
      IMPORTING
        is_alv_output TYPE lcl_app=>ty_s_alv_output.

    METHODS _display_selected_requests.

    METHODS _display_selected_object
      IMPORTING im_s_alv_output TYPE ty_s_alv_output.

    METHODS _refresh_app.

    METHODS _clean.

ENDCLASS.

CLASS lcl_app IMPLEMENTATION.

  METHOD constructor.

    DATA(lo_split) = NEW cl_gui_splitter_container( parent = cl_gui_container=>default_screen
                                                    no_autodef_progid_dynnr = abap_true
                                                    rows = 2
                                                    columns = 1 ).

    g_container_up = lo_split->get_container( row = 1 column = 1 ).
    g_container_down = lo_split->get_container( row = 2 column = 1 ).

    lo_split->set_row_height( id = 2 height = 25  ).

    alv_qry = ir_alv_qry.

  ENDMETHOD.

  METHOD run.

    r_transport_request = _condense( ir_transport_request ).

    at_transport_request = it_transport_request.

    rfc_compare_destination = iv_rfc_compare_destination.
    tr_descr = iv_tr_descr.
    ai_compare = iv_compare.

    alv_output = alv_output_full = _find_data(
        iv_rfc_compare_destination = iv_rfc_compare_destination
        ir_transport_request       = r_transport_request
        it_transport_request       = it_transport_request
         ).

    _set_app_title( ).

    _display_main_alv( ).

    DATA(lt_all_collisions) = _find_all_collisions( ).
    _display_collisions_alv( lt_all_collisions ).

  ENDMETHOD.

  METHOD _refresh_app.

    ycl_trm_transport_request=>clear_cache(  ).

    alv_output = alv_output_full = _find_data(
        iv_rfc_compare_destination = rfc_compare_destination
        ir_transport_request       = r_transport_request
        it_transport_request       = at_transport_request ).

    alv->refresh( refresh_mode = if_salv_c_refresh=>full ).

    DATA(lt_all_collisions) = _find_all_collisions( ).
    _display_collisions_alv( lt_all_collisions ).

  ENDMETHOD.

  METHOD on_user_command.

    CASE e_salv_function.

      WHEN 'SHOW_COLLISIONS'.
        DATA(lt_selected_ojb_collisions) = _find_selected_obj_collisions( ).
        _display_collisions_alv( lt_selected_ojb_collisions ).

      WHEN 'SHOW_ALL_COLLISIONS'.
        DATA(lt_all_collisions) = _find_all_collisions( ).
        _display_collisions_alv( lt_all_collisions ).

        " Deselect ALV rows
        alv->get_selections( )->set_selected_rows( VALUE #( ) ).
        alv->refresh( ).

      WHEN 'COMPARE'.
        _compare( ).

      WHEN 'COMPARE_OBJECT'.
        _compare_to_destination_system( ).

      WHEN 'RELEASE'.
        _release_transport_requests( go_log ).

      WHEN 'CREATE_RELEASE_TOC'.
        _create_and_release_toc( go_log ).

      WHEN 'SELECT_ALL'.
        _select_all( abap_true ).

      WHEN 'DESELECT_ALL'.
        _select_all( abap_false ).

      WHEN 'DISPLAY_SELECTED_REQUESTS'.


        DATA(lt_selected_rows) = alv->get_selections( )->get_selected_rows( ).

        IF lt_selected_rows IS INITIAL.
          _display_selected_requests( ).

        ELSEIF lines( lt_selected_rows ) EQ 1.
          DATA(ls_alv_output) = alv_output[ lt_selected_rows[ 1 ] ].
          _display_selected_object( ls_alv_output ).

        ELSE.

          MESSAGE 'Select only one object' TYPE 'S' DISPLAY LIKE 'E'.
          RETURN.

        ENDIF.

      WHEN 'REFRESH_ALVS'.
        _refresh_app( ).

      WHEN 'CLEAN'.
        _clean( ).

      WHEN OTHERS.
        MESSAGE |Function { e_salv_function } not implemented| TYPE 'S' DISPLAY LIKE 'E'.
    ENDCASE.


  ENDMETHOD.

  METHOD _compare_to_destination_system.

    " Codigo copiado y adaptaco del programa SREPO ( CLASS_LCL_EVENT_RECEIVER - METHOD handle_double_click - CASE DYNPRO 0300 )

    DATA disp_comp TYPE progname.
    DATA ls_infoline1a TYPE vrsinfolna.
    DATA ls_infoline1b TYPE vrsinfolnb.
    DATA ls_infoline2a TYPE vrsinfolna.
    DATA ls_infoline2b TYPE vrsinfolnb.
    DATA l_objname TYPE vrsd-objname.
    DATA l_objtype TYPE vrsd-objtype.
    DATA lt_versno TYPE TABLE OF vrsn.
    DATA lt_vrsd TYPE TABLE OF vrsd.
    DATA ls_vrsd TYPE vrsd.
    DATA lt_versno_rem TYPE TABLE OF vrsn.
    DATA lt_vrsd_rem TYPE TABLE OF vrsd.
    DATA ls_vrsd_rem TYPE vrsd.

    DATA(lt_selected_lines) = alv->get_selections( )->get_selected_rows( ).
    IF lines( lt_selected_lines ) = 0.
      MESSAGE |No object selected| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    IF lines( lt_selected_lines ) <> 1.
      MESSAGE |Compare with only one object| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    DATA(ls_alv_output) = alv_output[ lt_selected_lines[ 1 ] ].
    IF ls_alv_output-its_new IS NOT INITIAL.
      MESSAGE |Object { ls_alv_output-fragname } does not exist in destination system| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.
    IF ls_alv_output-object = 'TOBJ'.
      MESSAGE |Object type TOBJ cannot be compare| TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

*& get  display report name. ********
    CALL FUNCTION 'SVRS_GET_OBJECT_REPORTS'
      EXPORTING
        objtype  = ls_alv_output-fragment
      IMPORTING
        rep_comp = disp_comp.   "  dir_f5_report
    IF disp_comp IS INITIAL.
      MESSAGE s016(tsys) WITH ls_alv_output-fragment DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

*& display result of remote compare.
    ls_infoline1a = ls_alv_output-fragname.
    ls_infoline2a = ls_alv_output-fragname.
    l_objname = ls_alv_output-fragname.
    l_objtype = ls_alv_output-fragment.
*& get local version data.
    CALL FUNCTION 'SVRS_GET_VERSION_DIRECTORY_46'
      EXPORTING
        objname      = l_objname
        objtype      = l_objtype
      TABLES
        lversno_list = lt_versno
        version_list = lt_vrsd
      EXCEPTIONS
        no_entry     = 1
        OTHERS       = 2.
    IF sy-subrc <> 0.
      MESSAGE 'Unexpected error' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    READ TABLE lt_vrsd INTO ls_vrsd WITH KEY versno = '00000'.
    ls_infoline1b-korrnum = ls_vrsd-korrnum .
    ls_infoline1b-author = ls_vrsd-author .
    ls_infoline1b-datum =  ls_vrsd-datum.

*& get remote  version data.
    CALL FUNCTION 'SVRS_GET_VERSION_DIRECTORY_46'
      DESTINATION rfc_compare_destination
      EXPORTING
        objname      = l_objname
        objtype      = l_objtype
      TABLES
        lversno_list = lt_versno_rem
        version_list = lt_vrsd_rem
      EXCEPTIONS
        no_entry     = 1
        OTHERS       = 2.
    IF sy-subrc <> 0.

    ENDIF.
    READ TABLE lt_vrsd_rem INTO  ls_vrsd_rem
                          WITH  KEY versno = '00000'.
    ls_infoline2b-korrnum  = ls_vrsd_rem-korrnum .
    ls_infoline2b-author  = ls_vrsd_rem-author .
    ls_infoline2b-datum =  ls_vrsd_rem-datum.

    SUBMIT (disp_comp) AND RETURN
            WITH objname  = ls_alv_output-fragname
            WITH objnam2  = ls_alv_output-fragname
            WITH versno1  = '00000'
            WITH versno2  = '00000'
            WITH objtyp1  = ls_alv_output-fragment
            WITH objtyp2  = ls_alv_output-fragment
            WITH infoln1a = ls_infoline1a
            WITH infoln1b = ls_infoline1b
            WITH infoln2a = ls_infoline2a
            WITH infoln2b = ls_infoline2b
            WITH log_dest = rfc_compare_destination
            WITH rem_syst = rfc_compare_destination.


  ENDMETHOD.

  METHOD _display_collisions_alv.

    alv_collisions_output = it_collisions.

    SORT alv_collisions_output BY request.
    DELETE ADJACENT DUPLICATES FROM alv_collisions_output.

    IF lines( alv_collisions_output ) > 0.

      IF total_collisions IS INITIAL.
        total_collisions = lines( alv_collisions_output ).
      ENDIF.

      TRY.
          DATA(lt_colissions_data) = ycl_trm_transport_request=>get_by_attributes(
                                      im_s_query_by_attr     = VALUE #( transportrequestid = VALUE #( FOR ls_collisions_ouput IN alv_collisions_output
                                                                                                        ( sign = 'I'
                                                                                                          option = 'EQ'
                                                                                                          low = ls_collisions_ouput-request )
                                                                                                     )
                                                                       )
                                    ).

          DATA(lv_name) = VALUE ad_namtext(  ).
          alv_collisions_output = VALUE #( FOR lo_collisions_data IN lt_colissions_data
            ( request     = lo_collisions_data->get_code(  )
              description = lo_collisions_data->get_description(  )
              user        = lo_collisions_data->get_owner( IMPORTING ex_name = lv_name )
              user_name   = lv_name ) ).

        CATCH ycx_trm_transport_request.

      ENDTRY.

    ENDIF.

    IF alv_collisions IS NOT BOUND.
      cl_salv_table=>factory(
        EXPORTING
          r_container = g_container_down
        IMPORTING
          r_salv_table = alv_collisions
        CHANGING
          t_table      = alv_collisions_output ).
    ENDIF.

    alv_collisions->set_data( CHANGING t_table = alv_collisions_output ).

    CAST cl_salv_column_table( alv_collisions->get_columns( )->get_column( 'REQUEST' ) )->set_key( abap_true ).
    CAST cl_salv_column_table( alv_collisions->get_columns( )->get_column( 'REQUEST' ) )->set_cell_type( if_salv_c_cell_type=>hotspot ).
    CAST cl_salv_column_table( alv_collisions->get_columns( )->get_column( 'REQUEST' ) )->set_tooltip( 'Navigate to Transport Request' ).

    CAST cl_salv_column_table( alv_collisions->get_columns( )->get_column( 'DESCRIPTION' ) )->set_cell_type( if_salv_c_cell_type=>hotspot ).
    CAST cl_salv_column_table( alv_collisions->get_columns( )->get_column( 'DESCRIPTION' ) )->set_tooltip( 'Navigate to SES' ).

    alv_collisions->get_functions( )->set_all( abap_true ).
    alv_collisions->get_columns( )->set_optimize( abap_true ).
    alv_collisions->get_selections( )->set_selection_mode( if_salv_c_selection_mode=>multiple ).

    CAST cl_salv_column_table( alv_collisions->get_columns( )->get_column( 'USER_NAME' ) )->set_short_text( CONV #( 'Owner name' ) ).
    CAST cl_salv_column_table( alv_collisions->get_columns( )->get_column( 'USER_NAME' ) )->set_medium_text( CONV #( 'Owner name' ) ).
    CAST cl_salv_column_table( alv_collisions->get_columns( )->get_column( 'USER_NAME' ) )->set_long_text( CONV #( 'Owner name' ) ).
    CAST cl_salv_column_table( alv_collisions->get_columns( )->get_column( 'USER' ) )->set_f4( abap_false ).

    DATA(lo_functions) = alv_collisions->get_functions( ).
    lo_functions->set_all( abap_true ).

    TRY.
        lo_functions->add_function( name = 'SHOW_TR_COLLISIONS'
                                    tooltip = 'Select a TR for getting its collisions'
                                    text = 'Show TR collisions'
                                    position = if_salv_c_function_position=>right_of_salv_functions ).
      CATCH cx_salv_existing.
    ENDTRY.

    TRY.
        lo_functions->add_function( name = 'SHOW_TR_ALL_COLLISIONS'
                                    tooltip = 'Show all collisions'
                                    text = 'Show all collisions'
                                    position = if_salv_c_function_position=>right_of_salv_functions ).
      CATCH cx_salv_existing.
    ENDTRY.

    SET HANDLER on_user_command_collisions FOR alv_collisions->get_event( ).
    SET HANDLER on_click_collisions FOR alv_collisions->get_event( ).

    IF total_collisions EQ lines( alv_collisions_output ).
      alv_collisions->get_display_settings( )->set_list_header( |Collisions ( { lines( alv_collisions_output ) } )| ).
    ELSE.
      alv_collisions->get_display_settings( )->set_list_header( |Collisions ( { lines( alv_collisions_output ) }/{ total_collisions } )| ).
    ENDIF.

    alv_collisions->display( ).

  ENDMETHOD.

  METHOD _find_all_collisions.

    LOOP AT alv_output_full ASSIGNING FIELD-SYMBOL(<ls_alv_output>).
      INSERT LINES OF VALUE ty_t_collisions_output(
        FOR lv_collisions IN <ls_alv_output>-collisions
            ( request = lv_collisions ) )  INTO TABLE rt_collisions.
    ENDLOOP.

  ENDMETHOD.

  METHOD _find_selected_obj_collisions.

    DATA(lt_rows) = alv->get_selections( )->get_selected_rows( ).
    IF lines( lt_rows ) = 0.
      rt_collisions = _find_all_collisions( ).
      RETURN.
    ENDIF.

    LOOP AT lt_rows ASSIGNING FIELD-SYMBOL(<lv_index>).
      INSERT LINES OF VALUE ty_t_collisions_output(
        FOR lv_collisions IN alv_output[ <lv_index> ]-collisions
            ( request = lv_collisions ) )  INTO TABLE rt_collisions.
    ENDLOOP.

  ENDMETHOD.

  METHOD _find_data.
    alv_qry->execute(
        iv_rfc_compare_destination = iv_rfc_compare_destination
        iv_compare                 = ai_compare
        ir_transport_request       = ir_transport_request
        it_transport_request       = it_transport_request
        ).
    rt_result = CORRESPONDING #( alv_qry->result ).
  ENDMETHOD.

  METHOD _display_main_alv.

    DATA: lt_alv TYPE ty_t_alv_output.
    IF it_objects IS NOT INITIAL.
      alv_output = it_objects.
    ELSE.
      alv_output = alv_output_full.
    ENDIF.

    IF alv IS NOT BOUND.

      cl_salv_table=>factory(
        EXPORTING
          r_container = g_container_up
        IMPORTING
          r_salv_table = alv
        CHANGING
          t_table      = alv_output ).

    ENDIF.

    alv->set_data(
      CHANGING
        t_table = alv_output ).

    _prepare_alv( ).

    alv->display( ).

  ENDMETHOD.

  METHOD _set_comparation_mode.
    CAST cl_salv_column_table( alv->get_columns( )->get_column( 'FRAGID' ) )->set_visible( value = ai_compare ).
    CAST cl_salv_column_table( alv->get_columns( )->get_column( 'FRAGMENT' ) )->set_visible( value = ai_compare ).
    CAST cl_salv_column_table( alv->get_columns( )->get_column( 'FRAGNAME' ) )->set_visible( value = ai_compare ).
    CAST cl_salv_column_table( alv->get_columns( )->get_column( 'ITS_NEW' ) )->set_visible( value = ai_compare ).
    CAST cl_salv_column_table( alv->get_columns( )->get_column( 'ITS_EQUAL' ) )->set_visible( value = ai_compare ).
    DATA(lo_functions) = alv->get_functions( ).
    IF ai_compare EQ abap_true.

      TRY.

          lo_functions->add_function( name = 'COMPARE_OBJECT'
                                      tooltip = 'Compare Object'
                                      text = 'Compare Object'
                                      icon = CONV #( icon_compare )
                                      position = if_salv_c_function_position=>right_of_salv_functions ).
          lo_functions->remove_function( name = 'COMPARE' ).
        CATCH cx_salv_existing  cx_salv_wrong_call cx_salv_not_found.
      ENDTRY.

    ELSE.
      lo_functions->add_function( name = 'COMPARE'
                           tooltip = 'Compare'
                           text = |Compare with { rfc_compare_destination }|
                           icon = CONV #( icon_compare )
                           position = if_salv_c_function_position=>right_of_salv_functions ).
      TRY.
          lo_functions->remove_function( name = 'COMPARE_OBJECT' ).
        CATCH cx_salv_existing  cx_salv_wrong_call cx_salv_not_found.
      ENDTRY.
    ENDIF.


  ENDMETHOD.

  METHOD _alv_add_exclusive_quality.

    IF rfc_compare_destination <> ycl_trm_transport_request=>get_customizing( )-rfc_to_quality." rfc_destintations-quality.
      RETURN.
    ENDIF.

    DATA(lo_functions) = alv->get_functions( ).

    TRY.
        lo_functions->add_function( name = 'CREATE_RELEASE_TOC'
                                    tooltip = 'Create Transport of Copies'
                                    text = 'Create Transport of Copies'
                                    icon = CONV #( icon_transport )
                                    position = if_salv_c_function_position=>right_of_salv_functions ).
      CATCH cx_salv_existing.
    ENDTRY.

    TRY.
        lo_functions->add_function( name = 'SELECT_ALL'
                                    tooltip = 'Select all objects'
                                    text = 'Select All'
                                    icon = CONV #( icon_select_all )
                                    position = if_salv_c_function_position=>right_of_salv_functions ).
      CATCH cx_salv_existing.
    ENDTRY.

    TRY.
        lo_functions->add_function( name = 'DESELECT_ALL'
                                    tooltip = 'Deselect all objects'
                                    text = 'Deselect All'
                                    icon = CONV #( icon_deselect_all )
                                    position = if_salv_c_function_position=>right_of_salv_functions ).
      CATCH cx_salv_existing.
    ENDTRY.

    CAST cl_salv_column_table( alv->get_columns( )->get_column( 'CHECKBOX' ) )->set_short_text( CONV #( 'Add to ToC' ) ).
    CAST cl_salv_column_table( alv->get_columns( )->get_column( 'CHECKBOX' ) )->set_medium_text( CONV #( 'Add to ToC' ) ).
    CAST cl_salv_column_table( alv->get_columns( )->get_column( 'CHECKBOX' ) )->set_long_text( CONV #( 'Add to Transport of Copy' ) ).
    CAST cl_salv_column_table( alv->get_columns( )->get_column( 'CHECKBOX' ) )->set_alignment( cl_salv_column_table=>centered ).
    CAST cl_salv_column_table( alv->get_columns( )->get_column( 'CHECKBOX' ) )->set_cell_type( if_salv_c_cell_type=>checkbox_hotspot ).


    LOOP AT alv_output ASSIGNING FIELD-SYMBOL(<ls_alv_output>).

      <ls_alv_output>-checkbox = SWITCH #( ai_compare
                                           WHEN abap_false THEN abap_true
                                           WHEN abap_true
                                            THEN COND #( WHEN <ls_alv_output>-not_compared = abap_true THEN abap_true
                                                         WHEN <ls_alv_output>-its_new EQ abap_true THEN abap_true
                                                         WHEN <ls_alv_output>-its_equal EQ abap_false THEN abap_true
                                                         ELSE abap_false )
                                           ELSE abap_true
                                            ).

    ENDLOOP.

  ENDMETHOD.

  METHOD _alv_add_exclusive_productive.

    IF rfc_compare_destination <> ycl_trm_transport_request=>get_customizing( )-rfc_to_productive.
      RETURN.
    ENDIF.

    DATA(lo_functions) = alv->get_functions( ).

    TRY.
        lo_functions->add_function( name = 'RELEASE'
                                    tooltip = 'Release'
                                    text = 'Release'
                                    icon = CONV #( icon_transport )
                                    position = if_salv_c_function_position=>right_of_salv_functions ).
      CATCH cx_salv_existing.
    ENDTRY.

    TRY.
        lo_functions->add_function( name = 'SELECT_ALL'
                                    tooltip = 'Select all objects'
                                    text = 'Select All'
                                    icon = CONV #( icon_select_all )
                                    position = if_salv_c_function_position=>right_of_salv_functions ).
      CATCH cx_salv_existing.
    ENDTRY.

    TRY.
        lo_functions->add_function( name = 'DESELECT_ALL'
                                    tooltip = 'Deselect all objects'
                                    text = 'Deselect All'
                                    icon = CONV #( icon_deselect_all )
                                    position = if_salv_c_function_position=>right_of_salv_functions ).
      CATCH cx_salv_existing.
    ENDTRY.

    DATA lt_users TYPE STANDARD TABLE OF sy-uname WITH DEFAULT KEY.
    lt_users = VALUE #(
      ( '00752978' )
      ( '00739817' )
      ( '03750198' )
       ).

    IF line_exists( lt_users[ table_line = sy-uname ] ).
      TRY.
          lo_functions->add_function( name = 'CLEAN'
                                      tooltip = 'Clean TRs'
                                      text = 'Clean TRs'
                                      icon = CONV #( icon_delete )
                                      position = if_salv_c_function_position=>right_of_salv_functions ).
        CATCH cx_salv_existing.
      ENDTRY.
    ENDIF.

    DATA(lo_checkbox_column) = CAST cl_salv_column_table( alv->get_columns( )->get_column( 'CHECKBOX' ) ).
    lo_checkbox_column->set_short_text( CONV #( 'Reviewed' ) ).
    lo_checkbox_column->set_medium_text( CONV #( 'Has been reviewed' ) ).
    lo_checkbox_column->set_long_text( CONV #( 'Object has been reviewed' ) ).
    lo_checkbox_column->set_alignment( cl_salv_column_table=>centered ).
    lo_checkbox_column->set_cell_type( if_salv_c_cell_type=>checkbox_hotspot ).

  ENDMETHOD.

  METHOD _condense.

    rr_transport_request = ir_transport_request.
    LOOP AT rr_transport_request ASSIGNING FIELD-SYMBOL(<ls_transport_request>).
      <ls_transport_request>-low = condense( <ls_transport_request>-low ).
      <ls_transport_request>-high = condense( <ls_transport_request>-high ).
    ENDLOOP.

  ENDMETHOD.


  METHOD _release_transport_requests.

    DATA lv_answer TYPE char01.

    IF rfc_compare_destination <> ycl_trm_transport_request=>get_customizing( )-rfc_to_productive.
      MESSAGE 'Release request only for production transports' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    IF line_exists( alv_output[ checkbox = abap_false ] ).
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = 'Release requests'
          text_question         = |There are objects that have not been reviewed. Are you sure you want to release?|
          text_button_1         = 'Yes'
          text_button_2         = 'No'
          default_button        = '2'
          display_cancel_button = ''
        IMPORTING
          answer                = lv_answer.
      IF lv_answer = '2'. " No
        RETURN.
      ENDIF.

    ENDIF.

    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        titlebar              = 'Release requests'
        text_question         = |Do you want to release { lines( at_transport_request ) } requests?|
        text_button_1         = 'Yes'
        text_button_2         = 'No'
        default_button        = '2'
        display_cancel_button = ''
      IMPORTING
        answer                = lv_answer.
    IF lv_answer = '2'.
      RETURN.
    ENDIF.

    LOOP AT at_transport_request ASSIGNING FIELD-SYMBOL(<lo_transport_request>).
      TRY.
          <lo_transport_request>->release( im_check_released = abap_true im_release_tasks = abap_true ).
        CATCH ycx_trm_transport_request INTO DATA(lx_release).
      ENDTRY.
    ENDLOOP.

    IF io_log->has_messages( ).
      io_log->display( ).
    ENDIF.

  ENDMETHOD.

  METHOD on_click.

    " Select/ UnSelect Checkbox
    ASSIGN alv_output[ row ] TO FIELD-SYMBOL(<ls_alv_output>).
    IF <ls_alv_output> IS NOT ASSIGNED.
      RETURN.
    ENDIF.

    CASE column.
      WHEN 'CHECKBOX'.
        <ls_alv_output> = _on_click_on_checkbox( <ls_alv_output> ).
        alv->refresh( ).

      WHEN 'ITS_CUSTOMIZING'.
        _on_click_on_its_customizing( <ls_alv_output> ).

    ENDCASE.

  ENDMETHOD.

  METHOD on_click_collisions.
    " Select/ UnSelect Checkbox
    ASSIGN alv_collisions_output[ row ] TO FIELD-SYMBOL(<ls_alv_output>).
    IF <ls_alv_output> IS NOT ASSIGNED.
      RETURN.
    ENDIF.

    CASE column.

      WHEN 'DESCRIPTION'.
        lcl_utils=>open_on_browser( CONV #( <ls_alv_output>-description ) ).

      WHEN 'REQUEST'.
        lcl_utils=>navigate_to_request( <ls_alv_output>-request ).

    ENDCASE.

  ENDMETHOD.

  METHOD _create_and_release_toc.
    TYPES: lty_t_request_keys TYPE STANDARD TABLE OF e071k WITH DEFAULT KEY,

           BEGIN OF lty_s_freely_objects,
             pgmid    TYPE e071-pgmid,
             object   TYPE e071-object,
             obj_name TYPE e071-obj_name,
             objfunc  TYPE e071-objfunc,
             keys     TYPE lty_t_request_keys,
             activity TYPE e071-activity,
             lang     TYPE e071-lang,
           END OF lty_s_freely_objects,

           lty_t_freely_objects TYPE STANDARD TABLE OF lty_s_freely_objects WITH DEFAULT KEY.

    DATA lt_objects TYPE lty_t_freely_objects.

*    " Los function groups tiene que ir enteros, sino pueden dan error al importar. Si se marca un solo objeto del FG, nos lo llevamos todo.

    LOOP AT alv_output ASSIGNING FIELD-SYMBOL(<ls_alv_ouput>) WHERE pgmid = 'R3TR' AND
                                                                    object = 'FUGR' AND
                                                                    checkbox = abap_true.

      IF line_exists( lt_objects[ pgmid = <ls_alv_ouput>-pgmid object = <ls_alv_ouput>-object obj_name = <ls_alv_ouput>-obj_name ] ).
        CONTINUE.
      ENDIF.

      io_log->info( |Function Group { <ls_alv_ouput>-obj_name } will be released completely'| ).

      INSERT VALUE #( pgmid = <ls_alv_ouput>-pgmid object = <ls_alv_ouput>-object obj_name = <ls_alv_ouput>-obj_name ) INTO TABLE lt_objects.

    ENDLOOP.

    IF ai_compare EQ abap_true.
      lt_objects = VALUE #( BASE lt_objects FOR ls_alv_output IN alv_output WHERE ( checkbox = abap_true )
          (  pgmid    = ls_alv_output-fragid
             object   = ls_alv_output-fragment
             obj_name = ls_alv_output-fragname
             objfunc  = ls_alv_output-objfunc
             keys     = ls_alv_output-keys
             activity = ls_alv_output-activity
             lang     = ls_alv_output-lang
              ) ).
    ELSE.
      lt_objects = VALUE #( BASE lt_objects FOR ls_alv_output IN alv_output WHERE ( checkbox = abap_true )
      (  pgmid    = ls_alv_output-pgmid
         object   = ls_alv_output-object
         obj_name = ls_alv_output-obj_name
         objfunc  = ls_alv_output-objfunc
         keys     = ls_alv_output-keys
         activity = ls_alv_output-activity
         lang     = ls_alv_output-lang ) ).
    ENDIF.

    DATA(lv_release) = VALUE abap_bool( ).
    DATA(lv_go_to_stms) = VALUE abap_bool( ).
    DATA(lv_description) = CONV as4text( |COPY - { tr_descr }| ).

    IF NOT _confirmation_popup(
             IMPORTING
               ex_releasing   = lv_release
               ex_description = lv_description
               ex_go_to_stms  = lv_go_to_stms ).

      TRY .
          DATA(lo_transport_request) = ycl_trm_transport_request=>create_request(
            EXPORTING
              iv_req_desc            = lv_description
              iv_req_type            = yif_trm_transport_request=>type-toc
              iv_target              = ycl_trm_transport_request=>get_customizing( )-request_target_system_quality
              im_o_parent_logger     = io_log
          ).

          lo_transport_request->lock(  ).

          lo_transport_request->add_objects(
              EXPORTING
                  im_t_e071  = CORRESPONDING #( lt_objects )
                  im_t_e071k = VALUE #( FOR custo_object IN lt_objects WHERE ( objfunc EQ yif_trm_tr_object=>function-customizing )
                                        FOR keys IN custo_object-keys
                                         ( keys )
                                      )
          ).

          lo_transport_request->unlock(  ).

          IF lv_release EQ abap_true.

            lo_transport_request->release( ).

          ENDIF.

        CATCH ycx_trm_transport_request.

      ENDTRY.

      io_log->display( ).

      IF NOT io_log->has_errors( ) AND
         lv_go_to_stms = abap_true AND
         lv_release = abap_true.
        CALL FUNCTION 'ABAP4_CALL_TRANSACTION' STARTING NEW TASK 'TEST'
          DESTINATION rfc_compare_destination
          EXPORTING
            tcode = 'STMS'.
      ENDIF.

    ENDIF.

  ENDMETHOD.

  METHOD _select_all.

    LOOP AT alv_output ASSIGNING FIELD-SYMBOL(<ls_alv_output>).

      <ls_alv_output>-checkbox = im_click.

    ENDLOOP.

    alv->refresh( ).

  ENDMETHOD.

  METHOD _confirmation_popup.

    re_confirm = cl_ci_query_attributes=>generic(
        p_name       = CONV #( sy-repid )
        p_title      = 'Create Transport of Copies'
        p_attributes = VALUE #( ( kind = 'S' text = 'Description'       ref = REF #( ex_description ) )
                                ( kind = 'C' text = 'Release directly'  ref = REF #( ex_releasing ) )
                                ( kind = 'C' text = 'Go to STMS'        ref = REF #( ex_go_to_stms ) ) )
        p_display    = abap_false ).

  ENDMETHOD.


  METHOD _set_app_title.

    CASE rfc_compare_destination.
      WHEN ycl_trm_transport_request=>get_customizing( )-rfc_to_productive.
        SET TITLEBAR 'PROD'.
      WHEN ycl_trm_transport_request=>get_customizing( )-rfc_to_quality.
        SET TITLEBAR 'QLTY'.
      WHEN OTHERS.
    ENDCASE.

  ENDMETHOD.


  METHOD _prepare_alv.

    DATA(lo_columns) = alv->get_columns( ).
    lo_columns->set_column_position( columnname = 'FRAGID' position = '1' ).
    lo_columns->set_column_position( columnname = 'FRAGMENT' position = '2' ).
    lo_columns->set_column_position( columnname = 'FRAGNAME' position = '3' ).
    lo_columns->set_column_position( columnname = 'PGMID' position = '4' ).
    lo_columns->set_column_position( columnname = 'OBJECT' position = '5' ).
    lo_columns->set_column_position( columnname = 'OBJ_NAME' position = '6' ).
    lo_columns->set_column_position( columnname = 'ITS_CUSTOMIZING' position = '7' ).
    lo_columns->set_column_position( columnname = 'COLLISIONS' position = '8' ).
    lo_columns->set_column_position( columnname = 'HAS_COLLISIONS' position = '9' ).
    lo_columns->set_column_position( columnname = 'ITS_NEW' position = '10' ).
    lo_columns->set_column_position( columnname = 'ITS_EQUAL' position = '11' ).
    lo_columns->set_column_position( columnname = 'CHECKBOX' position = '12' ).

    CAST cl_salv_column_table( alv->get_columns( )->get_column( 'FRAGID' ) )->set_key( abap_true ).
    CAST cl_salv_column_table( alv->get_columns( )->get_column( 'FRAGMENT' ) )->set_key( abap_true ).
    CAST cl_salv_column_table( alv->get_columns( )->get_column( 'FRAGNAME' ) )->set_key( abap_true ).

    CAST cl_salv_column_table( alv->get_columns( )->get_column( 'ITS_CUSTOMIZING' ) )->set_short_text( CONV #( |Type| ) ).
    CAST cl_salv_column_table( alv->get_columns( )->get_column( 'ITS_CUSTOMIZING' ) )->set_medium_text( CONV #( |Type| ) ).
    CAST cl_salv_column_table( alv->get_columns( )->get_column( 'ITS_CUSTOMIZING' ) )->set_long_text( CONV #( |Type| ) ).
    CAST cl_salv_column_table( alv->get_columns( )->get_column( 'ITS_CUSTOMIZING' ) )->set_alignment( cl_salv_column_table=>centered ).

    CAST cl_salv_column_table( alv->get_columns( )->get_column( 'HAS_COLLISIONS' ) )->set_short_text( CONV #( 'Has collisions' ) ).
    CAST cl_salv_column_table( alv->get_columns( )->get_column( 'HAS_COLLISIONS' ) )->set_medium_text( CONV #( 'Has collisions' ) ).
    CAST cl_salv_column_table( alv->get_columns( )->get_column( 'HAS_COLLISIONS' ) )->set_long_text( CONV #( 'Has collisions' ) ).
    CAST cl_salv_column_table( alv->get_columns( )->get_column( 'HAS_COLLISIONS' ) )->set_alignment( cl_salv_column_table=>centered ).

    CAST cl_salv_column_table( alv->get_columns( )->get_column( 'ITS_NEW' ) )->set_short_text( CONV #( 'It is new' ) ).
    CAST cl_salv_column_table( alv->get_columns( )->get_column( 'ITS_NEW' ) )->set_medium_text( CONV #( 'It is new' ) ).
    CAST cl_salv_column_table( alv->get_columns( )->get_column( 'ITS_NEW' ) )->set_long_text( CONV #( 'It is new' ) ).
    CAST cl_salv_column_table( alv->get_columns( )->get_column( 'ITS_NEW' ) )->set_alignment( cl_salv_column_table=>centered ).

    CAST cl_salv_column_table( alv->get_columns( )->get_column( 'ITS_EQUAL' ) )->set_short_text( CONV #( 'It is equal' ) ).
    CAST cl_salv_column_table( alv->get_columns( )->get_column( 'ITS_EQUAL' ) )->set_medium_text( CONV #( 'It is equal' ) ).
    CAST cl_salv_column_table( alv->get_columns( )->get_column( 'ITS_EQUAL' ) )->set_long_text( CONV #( 'It is equal' ) ).
    CAST cl_salv_column_table( alv->get_columns( )->get_column( 'ITS_EQUAL' ) )->set_alignment( cl_salv_column_table=>centered ).

    CAST cl_salv_column_table( alv->get_columns( )->get_column( 'OBJFUNC' ) )->set_visible( abap_false ).
    CAST cl_salv_column_table( alv->get_columns( )->get_column( 'NOT_COMPARED' ) )->set_visible( abap_false ).
    CAST cl_salv_column_table( alv->get_columns( )->get_column( 'ACTIVITY' ) )->set_visible( abap_false ).
    CAST cl_salv_column_table( alv->get_columns( )->get_column( 'LANG' ) )->set_visible( abap_false ).
    alv->get_columns( )->set_cell_type_column( 'CELL_STYLE' ).

    DATA(lo_functions) = alv->get_functions( ).
    lo_functions->set_all( abap_true ).

    TRY.
        lo_functions->add_function( name = 'REFRESH_ALVS'
                                    tooltip = 'Refresh data'
                                    icon = CONV #( icon_refresh )
                                    position = if_salv_c_function_position=>right_of_salv_functions ).
      CATCH cx_salv_existing.
    ENDTRY.

    TRY.
        lo_functions->add_function( name = 'DISPLAY_SELECTED_REQUESTS'
                                    tooltip = 'Display selected requests'
                                    icon = CONV #( icon_display )
                                    position = if_salv_c_function_position=>right_of_salv_functions ).
      CATCH cx_salv_existing.
    ENDTRY.

    TRY.
        lo_functions->add_function( name = 'SHOW_COLLISIONS'
                                    tooltip = 'Select an object for getting its collisions'
                                    text = 'Show object collisions'
                                    position = if_salv_c_function_position=>right_of_salv_functions ).
      CATCH cx_salv_existing.
    ENDTRY.

    TRY.
        lo_functions->add_function( name = 'SHOW_ALL_COLLISIONS'
                                    tooltip = 'Show all collisions'
                                    text = 'Show all collisions'
                                    position = if_salv_c_function_position=>right_of_salv_functions ).
      CATCH cx_salv_existing.
    ENDTRY.

    alv->get_columns( )->set_optimize( abap_true ).
    alv->get_selections( )->set_selection_mode( if_salv_c_selection_mode=>multiple ).

    IF alv_output EQ alv_output_full.
      alv->get_display_settings( )->set_list_header( |TR Objects ({ lines( alv_output ) })| ).
    ELSE.
      alv->get_display_settings( )->set_list_header( |TR Objects ({ lines( alv_output ) }/{ lines( alv_output_full ) })| ).
    ENDIF.

    " Sorting
    TRY.
        alv->get_sorts( )->clear( ).
        alv->get_sorts( )->add_sort( columnname = 'HAS_COLLISIONS'
                                     sequence = if_salv_c_sort=>sort_down ).

      CATCH cx_salv_existing.
    ENDTRY.

    SET HANDLER on_user_command FOR alv->get_event( ).
    SET HANDLER on_click FOR alv->get_event( ).
    SET HANDLER on_double_click FOR alv->get_event( ).

    _set_comparation_mode(  ).

    _alv_add_exclusive_quality( ).

    _alv_add_exclusive_productive( ).

  ENDMETHOD.


  METHOD _compare.

    ai_compare = abap_true.
    alv_output = alv_output_full = _find_data(
      iv_rfc_compare_destination = rfc_compare_destination
      ir_transport_request       = r_transport_request
      it_transport_request       = at_transport_request ).

    _prepare_alv( ).

    alv->refresh( ).

  ENDMETHOD.


  METHOD _on_click_on_checkbox.
    rs_alv_output = is_alv_output.
    rs_alv_output-checkbox = COND #( WHEN rs_alv_output-checkbox = abap_true THEN abap_false ELSE abap_true ).
  ENDMETHOD.


  METHOD _on_click_on_its_customizing.

    " Show key popup
    TYPES: BEGIN OF ty_s_customizing_key,
             mastername TYPE e071k-mastername,
             tabkey     TYPE e071k-tabkey,
           END OF ty_s_customizing_key,
           ty_t_customizing_key TYPE STANDARD TABLE OF ty_s_customizing_key WITH DEFAULT KEY.

    DATA(lt_keys) = CORRESPONDING ty_t_customizing_key( is_alv_output-keys ).

    IF lt_keys IS INITIAL.
      RETURN.
    ENDIF.

    TRY.
        cl_salv_table=>factory( IMPORTING r_salv_table = DATA(lo_salv_popup_key)
                                CHANGING t_table       = lt_keys ).

        lo_salv_popup_key->set_screen_popup(
          start_column = 1
          end_column   = 100
          start_line   = 1
          end_line     = 15 ).

        lo_salv_popup_key->get_columns( )->set_optimize( abap_true ).

        lo_salv_popup_key->display( ).
      CATCH cx_salv_msg.
    ENDTRY.

  ENDMETHOD.

  METHOD _on_click_on_object.

  ENDMETHOD.

  METHOD _find_selected_tr_collisions.
    DATA(lt_rows) = alv_collisions->get_selections( )->get_selected_rows( ).
    IF lines( lt_rows ) = 0.
      rt_collisions = alv_output.
      RETURN.
    ENDIF.
*
    LOOP AT lt_rows ASSIGNING FIELD-SYMBOL(<lv_index>).
      DATA(ls_collisions) = alv_collisions_output[ <lv_index> ].

      LOOP AT alv_output_full ASSIGNING FIELD-SYMBOL(<output>) WHERE collisions IS NOT INITIAL.
        IF line_exists( <output>-collisions[ table_line = ls_collisions-request  ] ).
          INSERT <output> INTO TABLE rt_collisions.
        ENDIF.
      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.

  METHOD on_user_command_collisions.
    CASE e_salv_function.

      WHEN 'SHOW_TR_COLLISIONS'.
        DATA(lt_selected_tr_collisions) = _find_selected_tr_collisions(  ).
        _display_main_alv( lt_selected_tr_collisions ).
      WHEN 'SHOW_TR_ALL_COLLISIONS'.

        _display_main_alv(  ).

        " Deselect ALV rows
        alv_collisions->get_selections( )->set_selected_rows( VALUE #( ) ).
        alv_collisions->refresh( ).

    ENDCASE.
  ENDMETHOD.

  METHOD _display_selected_requests.
    lcl_selected_transport_request=>create(  )->display( at_transport_request ).
  ENDMETHOD.

  METHOD _display_selected_object.

    DATA(lr_transport_request) = VALUE yif_trm_transport_request_db=>typ_r_transportrequestid( FOR transport_request IN at_transport_request ( sign = 'I' option = 'EQ' low = transport_request->get_code(   ) ) ).

    DATA(ls_entries_query) = VALUE yif_trm_transport_request_db=>typ_s_tr_entries_qry_by_attr( objectid     = VALUE #( ( sign = 'I' option = 'EQ' low = im_s_alv_output-fragid )   ( sign = 'I' option = 'EQ' low = im_s_alv_output-pgmid ) )
                                                                                               objecttype   = VALUE #( ( sign = 'I' option = 'EQ' low = im_s_alv_output-fragment ) ( sign = 'I' option = 'EQ' low = im_s_alv_output-object ) )
                                                                                               objectname   = VALUE #( ( sign = 'I' option = 'EQ' low = im_s_alv_output-fragname ) ( sign = 'I' option = 'EQ' low = im_s_alv_output-obj_name ) )
                                                                                             ).

    " Obtenemos las órdenes de Transporte en las que está contenido el objeto seleccionado
    DATA(lt_transport_request) = ycl_trm_transport_request=>get_by_attributes( im_s_query_by_attr = VALUE #( transportrequestid = lr_transport_request
                                                                                                             entries_attr       = ls_entries_query ) ).

    " Obtenemos las tareas en las que está contenido el objeto seleccionado
    INSERT LINES OF ycl_trm_transport_request=>get_by_attributes( im_s_query_by_attr = VALUE #( entries_attr = ls_entries_query
                                                                                                parentid     = lr_transport_request ) )
      INTO TABLE lt_transport_request.

    lcl_selected_transport_request=>create(  )->display( lt_transport_request ).

  ENDMETHOD.

  METHOD on_double_click.

    ASSIGN alv_output[ row ] TO FIELD-SYMBOL(<ls_alv_output>).
    IF <ls_alv_output> IS NOT ASSIGNED.
      RETURN.
    ENDIF.

    CASE column.

      WHEN 'FRAGID' OR 'FRAGMENT' OR 'FRAGNAME'.

        TRY.
            ycl_trm_tr_object=>navigate(
                iv_pgmid       = <ls_alv_output>-fragid
                iv_object      = <ls_alv_output>-fragment
                iv_object_name = <ls_alv_output>-fragname ).
          CATCH ycx_trm_transport_request INTO DATA(lox_transport_request).
            lox_transport_request->logger->display( ).
        ENDTRY.

      WHEN 'PGMID'  OR 'OBJECT' OR 'OBJ_NAME'.

        TRY.
            ycl_trm_tr_object=>navigate(
                iv_pgmid       = <ls_alv_output>-pgmid
                iv_object      = <ls_alv_output>-object
                iv_object_name = <ls_alv_output>-obj_name ).
          CATCH ycx_trm_transport_request INTO lox_transport_request.
            lox_transport_request->logger->display( ).
        ENDTRY.

    ENDCASE.

  ENDMETHOD.

  METHOD _clean.

    DATA(lo_log) = ycl_trm_logger=>new(  ).

    DATA(lt_tr_objects) = VALUE yif_trm_tr_object=>tab( ).

    lt_tr_objects = VALUE #( BASE lt_tr_objects
                             FOR tr_request IN gt_transport_requests
                             FOR entry IN tr_request->get_entries( im_include_task_objects = abap_true )
                                    ( entry )
                           ).
    TRY.
        DATA(lt_compare) = ycl_trm_compare_objects=>create( ycl_trm_transport_request=>get_customizing(  )-rfc_to_productive )->compare( lt_tr_objects ).

        DATA(lt_compare_equals) = lt_compare.

        " No se tienen en cuenta los objetos que tienen diferencias
        DELETE lt_compare_equals WHERE equal EQ abap_false.

        " Si no hay objetos iguales a Productivo, no se continua
        IF lt_compare_equals IS INITIAL.
          RETURN.
        ENDIF.

        " Se verifica si objetos a nivel de orden son iguales a Productivo
        LOOP AT gt_transport_requests ASSIGNING FIELD-SYMBOL(<lo_transport_request>).
          " OBJETOS A NIVEL DE ORDEN
          LOOP AT <lo_transport_request>->get_entries(  ) ASSIGNING FIELD-SYMBOL(<lo_entry>).
            " Si el sub-componente es igual a productivo se borra de la orden
            IF line_exists( lt_compare_equals[ fragid   = <lo_entry>->get_object_id( )
                                               fragment = <lo_entry>->get_object_type( )
                                               fragname = <lo_entry>->get_object_name( )
                                             ]
                          ).

              " Si el componente principal tiene todos sus subcomponentes iguales se borra de la orden
            ELSEIF line_exists( lt_compare_equals[ pgmid    = <lo_entry>->get_object_id( )
                                                   object   = <lo_entry>->get_object_type( )
                                                   obj_name = <lo_entry>->get_object_name( )
                                                 ]
                              ).
              " Se verifica que todos los sub-componentes del componente sean iguales a productivo
              LOOP AT lt_compare ASSIGNING FIELD-SYMBOL(<ls_compare>) WHERE pgmid    = <lo_entry>->get_object_id( )
                                                                        AND object   = <lo_entry>->get_object_type( )
                                                                        AND obj_name = <lo_entry>->get_object_name( )
                                                                        AND equal    EQ abap_false.
                EXIT.
              ENDLOOP.
              " Si todos los subcomponentes son iguales a productivo se borra el componente
              IF sy-subrc IS INITIAL.

                CONTINUE.

              ENDIF.

            ELSE.
              CONTINUE.
            ENDIF.

            TRY.
                <lo_transport_request>->delete_entry( <lo_entry> ).
                lo_log->info( |Object { <lo_entry>->get_object_id( ) }{ <lo_entry>->get_object_type( ) }{ <lo_entry>->get_object_name( ) } was deleted from Request { <lo_transport_request>->get_code(  ) }| ).

              CATCH ycx_trm_transport_request.
                lo_log->error( |Error deleting Object { <lo_entry>->get_object_id( ) }{ <lo_entry>->get_object_type( ) }{ <lo_entry>->get_object_name( ) } from Request { <lo_transport_request>->get_code(  ) }| ).
            ENDTRY.

          ENDLOOP.

          " OBJETOS A NIVEL DE TAREA
          " Se verifica si objetos a nivel de las tareas son iguales a Productivo
          LOOP AT <lo_transport_request>->get_tasks(  ) ASSIGNING FIELD-SYMBOL(<lo_task>).
            LOOP AT <lo_task>->get_entries(  ) ASSIGNING <lo_entry>.
              " Si el sub-componente es igual a productivo se borra de la tarea
              IF line_exists( lt_compare_equals[ fragid   = <lo_entry>->get_object_id( )
                                                 fragment = <lo_entry>->get_object_type( )
                                                 fragname = <lo_entry>->get_object_name( )
                                               ]
                            ).

                " Si el componente principal tiene todos sus subcomponentes iguales se borra de la orden
              ELSEIF line_exists( lt_compare_equals[ pgmid    = <lo_entry>->get_object_id( )
                                                     object   = <lo_entry>->get_object_type( )
                                                     obj_name = <lo_entry>->get_object_name( )
                                                   ]
                                ).
                " Se verifica que todos los sub-componentes del componente sean iguales a productivo
                LOOP AT lt_compare ASSIGNING <ls_compare> WHERE pgmid    = <lo_entry>->get_object_id( )
                                                            AND object   = <lo_entry>->get_object_type( )
                                                            AND obj_name = <lo_entry>->get_object_name( )
                                                            AND equal    EQ abap_false.
                  EXIT.
                ENDLOOP.
                " Si todos los subcomponentes son iguales a productivo se borra el componente
                IF sy-subrc IS INITIAL.

                  CONTINUE.

                ENDIF.


              ELSE.

                CONTINUE.

              ENDIF.

              TRY.
                  <lo_task>->delete_entry( <lo_entry> ).
                  lo_log->info( |Object { <lo_entry>->get_object_id( ) }{ <lo_entry>->get_object_type( ) }{ <lo_entry>->get_object_name( ) } was deleted from Task { <lo_task>->get_code(  ) }| ).
                CATCH ycx_trm_transport_request.
                  lo_log->error( |Error deleting Object { <lo_entry>->get_object_id( ) }{ <lo_entry>->get_object_type( ) }{ <lo_entry>->get_object_name( ) } from Task { <lo_task>->get_code(  ) }| ).
              ENDTRY.

            ENDLOOP.
          ENDLOOP.
        ENDLOOP.

        lo_log->display(  ).

        _refresh_app(  ).

      CATCH ycx_trm_transport_request.
        "handle exception
    ENDTRY.

  ENDMETHOD.

ENDCLASS.
