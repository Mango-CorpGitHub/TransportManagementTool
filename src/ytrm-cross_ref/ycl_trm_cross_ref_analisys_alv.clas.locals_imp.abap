*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations

CLASS lcl_analized_objects_alv DEFINITION.
  PUBLIC SECTION.
    DATA alv      TYPE REF TO cl_salv_table.
    DATA alv_data TYPE ycl_trm_cross_ref_analisys_alv=>ty_t_analyzed_objects.

    METHODS display
      IMPORTING it_data TYPE ycl_trm_cross_ref_analisys_alv=>ty_t_analyzed_objects.

    METHODS constructor
      IMPORTING io_container TYPE REF TO cl_gui_custom_container.

  PRIVATE SECTION.
    DATA container TYPE REF TO cl_gui_custom_container.

ENDCLASS.


CLASS lcl_analized_objects_alv IMPLEMENTATION.
  METHOD constructor.
    container = io_container.
  ENDMETHOD.

  METHOD display.
    alv_data = it_data.

    cl_salv_table=>factory( EXPORTING r_container  = container
                            IMPORTING r_salv_table = alv
                            CHANGING  t_table      = alv_data ).

    FINAL(lo_functions) = alv->get_functions( ).
    lo_functions->set_all( abap_true ).

    alv->get_columns( )->set_optimize( ).

    CAST cl_salv_column_table( alv->get_columns( )->get_column( 'PGMID' ) )->set_key( abap_true ).
    CAST cl_salv_column_table( alv->get_columns( )->get_column( 'TYPE' ) )->set_key( abap_true ).
    CAST cl_salv_column_table( alv->get_columns( )->get_column( 'NAME' ) )->set_key( abap_true ).

    alv->display( ).

    WRITE space.
  ENDMETHOD.
ENDCLASS.
