CLASS ycl_trm_cross_ref_analisys_alv DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES: BEGIN OF ty_s_dependencies,
             reference_fragid     TYPE pgmid,
             reference_fragment   TYPE trobjtype,
             reference_fragname   TYPE trobj_name,
             severity             TYPE icon-name,
             status               TYPE string,

             show_where_used_list TYPE string,
             cell_type_column     TYPE salv_t_int4_column,
             reference            TYPE REF TO yif_trm_cross_reference,
           END OF ty_s_dependencies.

    TYPES ty_t_dependencies TYPE STANDARD TABLE OF ty_s_dependencies WITH DEFAULT KEY.

    TYPES: BEGIN OF ty_s_analyzed_objects,
             pgmid    TYPE pgmid,
             type     TYPE trobjtype,
             name     TYPE trobj_name,
             analyzed TYPE icon-name,
           END OF ty_s_analyzed_objects,
           ty_t_analyzed_objects TYPE STANDARD TABLE OF ty_s_analyzed_objects WITH DEFAULT KEY.

    TYPES: BEGIN OF ty_s_where_is_used_objects,
             pgmid            TYPE pgmid,
             type             TYPE trobjtype,
             name             TYPE trobj_name,
             severity         TYPE icon-name,
             message          TYPE string,

             logger           TYPE REF TO yif_trm_logger,
             describe         TYPE string,
             cell_type_column TYPE salv_t_int4_column,
           END OF ty_s_where_is_used_objects,
           ty_t_where_is_used_objects TYPE STANDARD TABLE OF ty_s_where_is_used_objects WITH DEFAULT KEY.

    TYPES: BEGIN OF ty_s_field_comparison,
             fieldname TYPE string,
             fieldtype TYPE string,
             severity  TYPE icon-name,
             status    TYPE yif_trm_cross_reference=>ty_e_status,
           END OF ty_s_field_comparison,
           ty_t_field_comparison TYPE STANDARD TABLE OF ty_s_field_comparison WITH DEFAULT KEY.

    DATA split                      TYPE REF TO cl_gui_splitter_container.
    DATA split_container_down       TYPE REF TO cl_gui_splitter_container.
    DATA split_container_up         TYPE REF TO cl_gui_splitter_container.

    DATA container_up               TYPE REF TO cl_gui_container.
    DATA container_down             TYPE REF TO cl_gui_container.
    DATA container_down_left        TYPE REF TO cl_gui_container.
    DATA container_down_right       TYPE REF TO cl_gui_container.
    DATA container_up_left          TYPE REF TO cl_gui_container.
    DATA container_up_right         TYPE REF TO cl_gui_container.

    DATA alv_dependencies           TYPE REF TO cl_salv_table.
    DATA alv_dependencies_data      TYPE ty_t_dependencies.
    DATA alv_where_is_used_objects  TYPE REF TO cl_salv_table.
    DATA alv_field_comparison       TYPE REF TO cl_salv_table.
    DATA ai_o_object_text           TYPE REF TO cl_gui_textedit.
    DATA ai_o_dependency_text       TYPE REF TO cl_gui_textedit.

    DATA ai_rfc_destination         TYPE rfcdes-rfcdest.
    DATA ai_t_analyzed_objects      TYPE ty_t_analyzed_objects.
    DATA ai_t_where_is_used_objects TYPE ty_t_where_is_used_objects.
    DATA ai_t_field_comparison      TYPE ty_t_field_comparison.

    DATA ai_dimension               TYPE i.

    METHODS on_click
      FOR EVENT link_click OF cl_salv_events_table
      IMPORTING !row
                !column.

    METHODS on_user_command
      FOR EVENT added_function OF cl_salv_events
      IMPORTING e_salv_function.

    METHODS on_double_click
      FOR EVENT double_click OF cl_salv_events_table
      IMPORTING !row
                !column.

    METHODS on_objects_double_click
      FOR EVENT double_click OF cl_salv_events_table
      IMPORTING !row
                !column.

    METHODS on_objects_link_click
      FOR EVENT link_click OF cl_salv_events_table
      IMPORTING !row
                !column.

    METHODS on_objects_click
      FOR EVENT link_click OF cl_salv_events_table
      IMPORTING !row
                !column.

    METHODS display
      IMPORTING is_result TYPE ycl_trm_cross_ref_analisys=>ty_s_return.

    METHODS display_analyzed_objects
      IMPORTING io_container TYPE REF TO cl_gui_custom_container.

    METHODS free.

    METHODS constructor
      IMPORTING iv_rfc_comparison TYPE rfcdes-rfcdest
                io_container      TYPE REF TO cl_gui_custom_container.

  PRIVATE SECTION.
    CONSTANTS: BEGIN OF c_functions,
                 analyzed_objects TYPE salv_de_function VALUE 'analyzed_objects',
               END OF c_functions.

    DATA main_container TYPE REF TO cl_gui_custom_container.

    METHODS mapp_to_response
      IMPORTING it_result         TYPE yif_trm_cross_reference=>tab
      RETURNING VALUE(rt_display) TYPE ty_t_dependencies.

    METHODS on_click_on_show_where_used_l
      IMPORTING is_alv_output TYPE ty_s_dependencies.

    METHODS display_object_text
      IMPORTING is_object TYPE ty_s_where_is_used_objects.

    METHODS display_dependency_text
      IMPORTING is_alv_output TYPE ty_s_dependencies.

    METHODS map_analyzed_objects
      IMPORTING is_result_analized_objets_resu TYPE ycl_trm_cross_ref_analisys=>ty_s_pre_object_analisys
      RETURNING VALUE(rt_result)               LIKE ai_t_analyzed_objects.

    METHODS build_field_comparison_alv
      IMPORTING iv_title TYPE string.

    METHODS show_containers.

ENDCLASS.


CLASS ycl_trm_cross_ref_analisys_alv IMPLEMENTATION.
  METHOD constructor.
    main_container = io_container.
    ai_rfc_destination = iv_rfc_comparison.

    split = NEW cl_gui_splitter_container( parent                  = main_container
                                           no_autodef_progid_dynnr = abap_true
                                           rows                    = 2
                                           columns                 = 1 ).

    container_up = split->get_container( row    = 1
                                         column = 1 ).

    container_down = split->get_container( row    = 2
                                           column = 1 ).

    split_container_down = NEW cl_gui_splitter_container( parent                  = container_down
                                                          no_autodef_progid_dynnr = abap_true
                                                          rows                    = 1
                                                          columns                 = 2 ).

    container_down_left = split_container_down->get_container( row    = 1
                                                               column = 1 ).

    container_down_right = split_container_down->get_container( row    = 1
                                                                column = 2 ).

    split_container_up = NEW cl_gui_splitter_container( parent                  = container_up
                                                        no_autodef_progid_dynnr = abap_true
                                                        rows                    = 1
                                                        columns                 = 2 ).

    container_up_left = split_container_up->get_container( row    = 1
                                                           column = 1 ).

    container_up_right = split_container_up->get_container( row    = 1
                                                            column = 2 ).

    " Hide containers initially
    split->set_row_height( id     = 2
                           height = 0  ).

    split_container_down->set_column_width( id    = 2
                                            width = 0  ).

    split_container_up->set_column_width( id    = 2
                                          width = 0  ).
  ENDMETHOD.

  METHOD display.
    ai_t_analyzed_objects = map_analyzed_objects( is_result-analized_objets_resume ).
    alv_dependencies_data = mapp_to_response( is_result-result ).

    cl_salv_table=>factory( EXPORTING r_container  = container_up_left
                            IMPORTING r_salv_table = alv_dependencies
                            CHANGING  t_table      = alv_dependencies_data ).

    FINAL(lo_functions) = alv_dependencies->get_functions( ).
    lo_functions->set_all( abap_true ).

    TRY.
        lo_functions->add_function( name     = c_functions-analyzed_objects
                                    tooltip  = 'Analized Objects'
                                    text     = 'Analized Objects'
                                    icon     = CONV #( icon_display )
                                    position = if_salv_c_function_position=>right_of_salv_functions ).
      CATCH cx_salv_existing.
    ENDTRY.

    alv_dependencies->get_columns( )->set_optimize( ).

    CAST cl_salv_column_table( alv_dependencies->get_columns( )->get_column( 'REFERENCE_FRAGID' ) )->set_key( abap_true ).
    CAST cl_salv_column_table( alv_dependencies->get_columns( )->get_column( 'REFERENCE_FRAGMENT' ) )->set_key(
                                                                                                        abap_true ).
    CAST cl_salv_column_table( alv_dependencies->get_columns( )->get_column( 'REFERENCE_FRAGNAME' ) )->set_key(
                                                                                                        abap_true ).

    alv_dependencies->get_columns( )->set_cell_type_column( 'CELL_TYPE_COLUMN' ).

    CAST cl_salv_column_table( alv_dependencies->get_columns( )->get_column( 'SEVERITY' ) )->set_short_text(
                                                                                              CONV #( |Severity| ) ).
    CAST cl_salv_column_table( alv_dependencies->get_columns( )->get_column( 'SEVERITY' ) )->set_medium_text(
                                                                                              CONV #( |Severity| ) ).
    CAST cl_salv_column_table( alv_dependencies->get_columns( )->get_column( 'SEVERITY' ) )->set_long_text(
                                                                                              CONV #( |Severity| ) ).
    CAST cl_salv_column_table( alv_dependencies->get_columns( )->get_column( 'SEVERITY' ) )->set_alignment(
        cl_salv_column_table=>centered ).

    CAST cl_salv_column_table( alv_dependencies->get_columns( )->get_column( 'SHOW_WHERE_USED_LIST' ) )->set_short_text(
        CONV #( |Action| ) ).
    CAST cl_salv_column_table( alv_dependencies->get_columns( )->get_column( 'SHOW_WHERE_USED_LIST' ) )->set_medium_text(
        CONV #( |Action| ) ).
    CAST cl_salv_column_table( alv_dependencies->get_columns( )->get_column( 'SHOW_WHERE_USED_LIST' ) )->set_long_text(
        CONV #( |Action| ) ).
    CAST cl_salv_column_table( alv_dependencies->get_columns( )->get_column( 'SHOW_WHERE_USED_LIST' ) )->set_alignment(
        cl_salv_column_table=>centered ).

    TRY.
        alv_dependencies->get_sorts( )->clear( ).
        alv_dependencies->get_sorts( )->add_sort( columnname = 'SEVERITY'
                                                  sequence   = if_salv_c_sort=>sort_down ).

      CATCH cx_salv_existing.
    ENDTRY.

    SET HANDLER on_click FOR alv_dependencies->get_event( ).
    SET HANDLER on_user_command FOR alv_dependencies->get_event( ).
    SET HANDLER on_double_click FOR alv_dependencies->get_event( ).

    alv_dependencies->display( ).

    on_click_on_show_where_used_l( alv_dependencies_data[ 1 ] ).
    display_dependency_text( alv_dependencies_data[ 1 ] ).

    WRITE space.
  ENDMETHOD.

  METHOD mapp_to_response.
    LOOP AT it_result ASSIGNING FIELD-SYMBOL(<lo_reference_list>).

      APPEND INITIAL LINE TO rt_display ASSIGNING FIELD-SYMBOL(<ls_display>).
      <ls_display> = CORRESPONDING #( <lo_reference_list>->get_data( ) ).
      <ls_display>-reference            = <lo_reference_list>.

      <ls_display>-severity             = SWITCH #( <ls_display>-status
                                                    WHEN yif_trm_cross_reference=>c_status-also_in_transport_request THEN
                                                      icon_checked
                                                    WHEN yif_trm_cross_reference=>c_status-different_in_destination THEN
                                                      icon_led_yellow
                                                    WHEN yif_trm_cross_reference=>c_status-method_definition_dif_in_dest THEN
                                                      icon_led_yellow
                                                    WHEN yif_trm_cross_reference=>c_status-equal_in_destination THEN
                                                      icon_led_green
                                                    WHEN yif_trm_cross_reference=>c_status-exist_in_destination THEN
                                                      icon_led_green
                                                    WHEN yif_trm_cross_reference=>c_status-different_but_not_relevant THEN
                                                      icon_led_green
                                                    WHEN yif_trm_cross_reference=>c_status-only_in_source THEN
                                                      icon_led_red
                                                    WHEN yif_trm_cross_reference=>c_status-different THEN
                                                      icon_led_red
                                                    WHEN yif_trm_cross_reference=>c_status-definition_missing THEN
                                                      icon_led_red
                                                    WHEN yif_trm_cross_reference=>c_status-sap_reference THEN
                                                      icon_checked

                                                    WHEN yif_trm_cross_reference=>c_status-subobject_not_assigned THEN
                                                      icon_abap
                                                    WHEN yif_trm_cross_reference=>c_status-to_delete THEN
                                                      icon_abap ).

      <ls_display>-show_where_used_list = icon_reference_list.

      " Cell type:
      <ls_display>-cell_type_column     = VALUE #( ( columnname = 'SHOW_WHERE_USED_LIST'
                                                     value      = if_salv_c_cell_type=>button ) ).

    ENDLOOP.
  ENDMETHOD.

  METHOD on_click.
    ASSIGN alv_dependencies_data[ row ] TO FIELD-SYMBOL(<ls_alv_output>).
    IF <ls_alv_output> IS NOT ASSIGNED.
      RETURN.
    ENDIF.

    CASE column.

      WHEN 'SHOW_WHERE_USED_LIST'.
        show_containers( ).

        on_click_on_show_where_used_l( <ls_alv_output> ).
        display_dependency_text( <ls_alv_output> ).

    ENDCASE.
  ENDMETHOD.

  METHOD on_click_on_show_where_used_l.
    " Show list of dependencies....
    ai_t_where_is_used_objects = CORRESPONDING #( is_alv_output-reference->get_data( )-object_list ).
    SORT ai_t_where_is_used_objects BY severity DESCENDING.

    LOOP AT ai_t_where_is_used_objects ASSIGNING FIELD-SYMBOL(<ls_where_is_used_objects>).
      <ls_where_is_used_objects>-describe = icon_arrow_right.
      IF <ls_where_is_used_objects>-logger IS BOUND AND <ls_where_is_used_objects>-logger->has_messages( ).
        <ls_where_is_used_objects>-message = |Show errors|.

        INSERT VALUE #( columnname = 'MESSAGE'
                        value      = if_salv_c_cell_type=>hotspot  ) INTO TABLE <ls_where_is_used_objects>-cell_type_column.

      ENDIF.

      INSERT VALUE #( columnname = 'DESCRIBE'
                      value      = if_salv_c_cell_type=>button  ) INTO TABLE <ls_where_is_used_objects>-cell_type_column.

    ENDLOOP.

    LOOP AT container_down_left->children INTO FINAL(lo_children).
      lo_children->free( ).
    ENDLOOP.
    CLEAR alv_where_is_used_objects.

    cl_salv_table=>factory( EXPORTING r_container  = container_down_left
                            IMPORTING r_salv_table = alv_where_is_used_objects
                            CHANGING  t_table      = ai_t_where_is_used_objects ).

    alv_where_is_used_objects->get_display_settings( )->set_list_header(
        |{ is_alv_output-reference_fragname } - Where is used in transport request objects| ).

    alv_where_is_used_objects->get_columns( )->set_cell_type_column( 'CELL_TYPE_COLUMN' ).
    alv_where_is_used_objects->get_columns( )->set_optimize( ).

    alv_where_is_used_objects->get_sorts( )->clear( ).

    FINAL(lo_functions) = alv_where_is_used_objects->get_functions( ).
    lo_functions->set_all( abap_true ).

    CAST cl_salv_column_table( alv_where_is_used_objects->get_columns( )->get_column( 'PGMID' ) )->set_key( abap_true ).
    CAST cl_salv_column_table( alv_where_is_used_objects->get_columns( )->get_column( 'TYPE' ) )->set_key( abap_true ).
    CAST cl_salv_column_table( alv_where_is_used_objects->get_columns( )->get_column( 'NAME' ) )->set_key( abap_true ).

    CAST cl_salv_column_table( alv_where_is_used_objects->get_columns( )->get_column( 'SEVERITY' ) )->set_short_text(
        CONV #( |Severity| ) ).
    CAST cl_salv_column_table( alv_where_is_used_objects->get_columns( )->get_column( 'SEVERITY' ) )->set_medium_text(
        CONV #( |Severity| ) ).
    CAST cl_salv_column_table( alv_where_is_used_objects->get_columns( )->get_column( 'SEVERITY' ) )->set_long_text(
        CONV #( |Severity| ) ).
    CAST cl_salv_column_table( alv_where_is_used_objects->get_columns( )->get_column( 'SEVERITY' ) )->set_alignment(
        cl_salv_column_table=>centered ).

    CAST cl_salv_column_table( alv_where_is_used_objects->get_columns( )->get_column( 'MESSAGE' ) )->set_short_text(
        CONV #( |Message| ) ).
    CAST cl_salv_column_table( alv_where_is_used_objects->get_columns( )->get_column( 'MESSAGE' ) )->set_medium_text(
        CONV #( |Message| ) ).
    CAST cl_salv_column_table( alv_where_is_used_objects->get_columns( )->get_column( 'MESSAGE' ) )->set_long_text(
        CONV #( |Message| ) ).

    CAST cl_salv_column_table( alv_where_is_used_objects->get_columns( )->get_column( 'DESCRIBE' ) )->set_short_text(
        CONV #( |Describe| ) ).
    CAST cl_salv_column_table( alv_where_is_used_objects->get_columns( )->get_column( 'DESCRIBE' ) )->set_medium_text(
        CONV #( |Describe| ) ).
    CAST cl_salv_column_table( alv_where_is_used_objects->get_columns( )->get_column( 'DESCRIBE' ) )->set_long_text(
        CONV #( |Describe| ) ).
    CAST cl_salv_column_table( alv_where_is_used_objects->get_columns( )->get_column( 'DESCRIBE' ) )->set_alignment(
        cl_salv_column_table=>centered ).

    " Ocultar severity y message si no hay datos:
    " TODO: variable is assigned but never used (ABAP cleaner)
    LOOP AT ai_t_where_is_used_objects INTO DATA(ls_where_is_user_object) WHERE severity IS NOT INITIAL.
      CAST cl_salv_column_table( alv_where_is_used_objects->get_columns( )->get_column( 'SEVERITY' ) )->set_visible(
                                                                                                         abap_true ).
      TRY.
          alv_where_is_used_objects->get_sorts( )->add_sort( columnname = 'SEVERITY'
                                                             sequence   = if_salv_c_sort=>sort_down ).
        CATCH cx_salv_existing.
      ENDTRY.

      EXIT.
    ENDLOOP.
    IF sy-subrc <> 0.
      CAST cl_salv_column_table( alv_where_is_used_objects->get_columns( )->get_column( 'SEVERITY' ) )->set_visible(
                                                                                                         abap_false ).
    ENDIF.

    LOOP AT ai_t_where_is_used_objects INTO ls_where_is_user_object WHERE message IS NOT INITIAL.
      CAST cl_salv_column_table( alv_where_is_used_objects->get_columns( )->get_column( 'MESSAGE' ) )->set_visible(
                                                                                                        abap_true ).
      EXIT.
    ENDLOOP.
    IF sy-subrc <> 0.
      CAST cl_salv_column_table( alv_where_is_used_objects->get_columns( )->get_column( 'MESSAGE' ) )->set_visible(
                                                                                                        abap_false ).
    ENDIF.

    SET HANDLER on_objects_double_click FOR alv_where_is_used_objects->get_event( ).
    SET HANDLER on_objects_click FOR alv_where_is_used_objects->get_event( ).
    SET HANDLER on_objects_link_click FOR alv_where_is_used_objects->get_event( ).

    alv_where_is_used_objects->get_columns( )->set_optimize( ).

    display_object_text( ai_t_where_is_used_objects[ 1 ] ).

    alv_where_is_used_objects->display( ).
  ENDMETHOD.

  METHOD display_object_text.
    DATA(lv_text) = ycl_trm_tr_object=>get_code( iv_object_name = is_object-name
                                                 iv_pgmid       = is_object-pgmid
                                                 iv_object      = is_object-type ).

    " Add title
    DATA(lv_title) = |-----------------------------------------------------------|.
    lv_title = |{ lv_title }{ cl_abap_char_utilities=>cr_lf }Current System - { is_object-type } - { is_object-name }|.
    lv_title = |{ lv_title }{ cl_abap_char_utilities=>cr_lf }-----------------------------------------------------------|.

    lv_text = |{ lv_title }{ cl_abap_char_utilities=>cr_lf }{ cl_abap_char_utilities=>cr_lf }{ lv_text }|.

    IF ai_o_object_text IS NOT BOUND.
      CREATE OBJECT ai_o_object_text
        EXPORTING  wordwrap_mode              = cl_gui_textedit=>wordwrap_at_fixed_position
                   wordwrap_position          = 256
                   wordwrap_to_linebreak_mode = cl_gui_textedit=>false
                   parent                     = container_down_right
        EXCEPTIONS error_cntl_create          = 1
                   error_cntl_init            = 2
                   error_cntl_link            = 3
                   error_dp_create            = 4
                   gui_type_not_supported     = 5
                   OTHERS                     = 6.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

    ENDIF.

    ai_o_object_text->delete_text( EXCEPTIONS error_cntl_call_method = 1
                                              OTHERS                 = 2 ).
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    ai_o_object_text->set_textstream( EXPORTING  text                   = lv_text
                                      EXCEPTIONS error_cntl_call_method = 1
                                                 not_supported_by_gui   = 2
                                                 OTHERS                 = 3 ).
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    ai_o_object_text->set_readonly_mode( ).

    ai_o_object_text->set_toolbar_mode( 1 ).
  ENDMETHOD.

  METHOD display_dependency_text.
    TRY.

        ai_t_field_comparison = is_alv_output-reference->compare( ai_rfc_destination ).

        build_field_comparison_alv(
            |{ ai_rfc_destination } - { is_alv_output-reference_fragment } - { is_alv_output-reference_fragname }| ).

      CATCH cx_method_not_implemented.

        " Mostrar Not Supported

        LOOP AT container_up_right->children INTO FINAL(lo_children).
          lo_children->free( ).
        ENDLOOP.
        CLEAR ai_o_dependency_text.

        " Add title
        DATA(lv_title) = |-----------------------------------------------------------|.
        lv_title = |{ lv_title }{ cl_abap_char_utilities=>cr_lf }{ ai_rfc_destination } - { is_alv_output-reference_fragment } - { is_alv_output-reference_fragname }|.
        lv_title = |{ lv_title }{ cl_abap_char_utilities=>cr_lf }-----------------------------------------------------------|.

        FINAL(lv_text) = |{ lv_title }{ cl_abap_char_utilities=>cr_lf }{ cl_abap_char_utilities=>cr_lf }Not Supported|.

        CREATE OBJECT ai_o_dependency_text
          EXPORTING  wordwrap_mode              = cl_gui_textedit=>wordwrap_at_fixed_position
                     wordwrap_position          = 256
                     wordwrap_to_linebreak_mode = cl_gui_textedit=>false
                     parent                     = container_up_right
          EXCEPTIONS error_cntl_create          = 1
                     error_cntl_init            = 2
                     error_cntl_link            = 3
                     error_dp_create            = 4
                     gui_type_not_supported     = 5
                     OTHERS                     = 6.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.

        ai_o_dependency_text->delete_text( EXCEPTIONS error_cntl_call_method = 1
                                                      OTHERS                 = 2 ).
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.

        ai_o_dependency_text->set_textstream( EXPORTING  text                   = lv_text
                                              EXCEPTIONS error_cntl_call_method = 1
                                                         not_supported_by_gui   = 2
                                                         OTHERS                 = 3 ).
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.

        ai_o_dependency_text->set_readonly_mode( ).

    ENDTRY.
  ENDMETHOD.

  METHOD on_objects_double_click.
    ASSIGN ai_t_where_is_used_objects[ row ] TO FIELD-SYMBOL(<ls_where_is_used_objects>).
    IF <ls_where_is_used_objects> IS NOT ASSIGNED.
      RETURN.
    ENDIF.

    CASE column.

      WHEN 'PGMID' OR 'NAME' OR 'TYPE'.

        TRY.
            ycl_trm_tr_object=>navigate( iv_pgmid       = <ls_where_is_used_objects>-pgmid
                                         iv_object      = <ls_where_is_used_objects>-type
                                         iv_object_name = <ls_where_is_used_objects>-name ).
          CATCH ycx_trm_transport_request INTO FINAL(lox_transport_request).
            lox_transport_request->logger->display( ).
        ENDTRY.

    ENDCASE.
  ENDMETHOD.

  METHOD on_objects_click.
    ASSIGN ai_t_where_is_used_objects[ row ] TO FIELD-SYMBOL(<ls_where_is_used_objects>).
    IF <ls_where_is_used_objects> IS NOT ASSIGNED.
      RETURN.
    ENDIF.

    CASE column.

      WHEN 'DESCRIBE'.
        display_object_text( <ls_where_is_used_objects> ).

    ENDCASE.
  ENDMETHOD.

  METHOD free.
    IF split IS BOUND.
      split->free( ).
    ENDIF.
  ENDMETHOD.

  METHOD map_analyzed_objects.
    rt_result = VALUE #( FOR ls_analyzed_objects IN is_result_analized_objets_resu-analyzed_objects
                         ( pgmid    = ls_analyzed_objects-pgmid
                           type     = ls_analyzed_objects-obj_type
                           name     = ls_analyzed_objects-obj_name
                           analyzed = icon_okay ) ).

    rt_result = VALUE #( BASE rt_result FOR ls_not_analyzed_objects IN is_result_analized_objets_resu-not_analyzed_objects
                         ( pgmid    = ls_not_analyzed_objects-pgmid
                           type     = ls_not_analyzed_objects-obj_type
                           name     = ls_not_analyzed_objects-obj_name
                           analyzed = icon_cancel ) ).
  ENDMETHOD.

  METHOD on_double_click.
    ASSIGN alv_dependencies_data[ row ] TO FIELD-SYMBOL(<ls_alv_dependency_data>).
    IF <ls_alv_dependency_data> IS NOT ASSIGNED.
      RETURN.
    ENDIF.

    CASE column.

      WHEN 'REFERENCE_FRAGID' OR 'REFERENCE_FRAGMENT' OR 'REFERENCE_FRAGNAME'.

        TRY.
            <ls_alv_dependency_data>-reference->navigate( ).
          CATCH ycx_trm_transport_request INTO FINAL(lox_transport_request).
            lox_transport_request->logger->display( ).
        ENDTRY.

    ENDCASE.
  ENDMETHOD.

  METHOD on_user_command.
    CASE e_salv_function.

      WHEN c_functions-analyzed_objects.
        CALL FUNCTION 'YTRM_FM_CROSS_REF_ANALYZED_OBJ'.

      WHEN OTHERS.
        MESSAGE |Function { e_salv_function } not implemented| TYPE 'S' DISPLAY LIKE 'E'.
    ENDCASE.
  ENDMETHOD.

  METHOD display_analyzed_objects.
    NEW lcl_analized_objects_alv( io_container )->display( ai_t_analyzed_objects ).
  ENDMETHOD.

  METHOD build_field_comparison_alv.
    LOOP AT container_up_right->children INTO FINAL(lo_children).
      lo_children->free( ).
    ENDLOOP.
    CLEAR alv_field_comparison.

    cl_salv_table=>factory( EXPORTING r_container  = container_up_right
                            IMPORTING r_salv_table = alv_field_comparison
                            CHANGING  t_table      = ai_t_field_comparison ).

    FINAL(lo_functions) = alv_field_comparison->get_functions( ).
    lo_functions->set_all( abap_true ).

    alv_field_comparison->get_columns( )->set_optimize( ).

    CAST cl_salv_column_table( alv_field_comparison->get_columns( )->get_column( 'FIELDNAME' ) )->set_key( abap_true ).
    CAST cl_salv_column_table( alv_field_comparison->get_columns( )->get_column( 'FIELDNAME' ) )->set_short_text(
                                                                                                   'Field Name' ).
    CAST cl_salv_column_table( alv_field_comparison->get_columns( )->get_column( 'FIELDNAME' ) )->set_medium_text(
                                                                                                   'Field Name' ).
    CAST cl_salv_column_table( alv_field_comparison->get_columns( )->get_column( 'FIELDNAME' ) )->set_long_text(
                                                                                                   'Field Name' ).

    CAST cl_salv_column_table( alv_field_comparison->get_columns( )->get_column( 'FIELDTYPE' ) )->set_short_text(
                                                                                                   'Field Type' ).
    CAST cl_salv_column_table( alv_field_comparison->get_columns( )->get_column( 'FIELDTYPE' ) )->set_medium_text(
                                                                                                   'Field Type' ).
    CAST cl_salv_column_table( alv_field_comparison->get_columns( )->get_column( 'FIELDTYPE' ) )->set_long_text(
                                                                                                   'Field Type' ).

    TRY.
        alv_field_comparison->get_sorts( )->clear( ).
        alv_field_comparison->get_sorts( )->add_sort( columnname = 'SEVERITY'
                                                      sequence   = if_salv_c_sort=>sort_down ).

      CATCH cx_salv_existing.
    ENDTRY.

    alv_field_comparison->get_display_settings( )->set_list_header( CONV #( iv_title ) ).

    alv_field_comparison->display( ).
  ENDMETHOD.

  METHOD show_containers.
    split->get_row_height( EXPORTING id     = 2
                           IMPORTING result = ai_dimension ).
    IF ai_dimension = 0.
      split->set_row_height( id     = 2
                             height = 50  ).
    ENDIF.

    split_container_down->get_column_width( EXPORTING id     = 2
                                            IMPORTING result = ai_dimension ).
    IF ai_dimension = 0.
      split_container_down->set_column_width( id    = 2
                                              width = 50  ).
    ENDIF.

    split_container_up->get_column_width( EXPORTING id     = 2
                                          IMPORTING result = ai_dimension ).
    IF ai_dimension = 0.
      split_container_up->set_column_width( id    = 2
                                            width = 50  ).
    ENDIF.
  ENDMETHOD.

  METHOD on_objects_link_click.
    ASSIGN ai_t_where_is_used_objects[ row ] TO FIELD-SYMBOL(<ls_where_is_used_objects>).
    IF <ls_where_is_used_objects> IS NOT ASSIGNED.
      RETURN.
    ENDIF.

    CASE column.

      WHEN 'MESSAGE'.
        IF <ls_where_is_used_objects>-logger IS BOUND.
          <ls_where_is_used_objects>-logger->display( iv_delete_messages_after = abap_false ).
        ENDIF.

    ENDCASE.
  ENDMETHOD.
ENDCLASS.
