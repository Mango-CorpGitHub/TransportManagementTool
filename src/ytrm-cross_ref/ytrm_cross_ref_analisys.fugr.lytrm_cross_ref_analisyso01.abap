*---------------------------------------------------------------------*
***INCLUDE LYTRM_CROSS_REF_ANALISYSO01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS '0100'.
* SET TITLEBAR 'xxx'.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module RUN_APP OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE run_app OUTPUT.

  alv_container = NEW cl_gui_custom_container( 'CC_ALV' ).

  alv_viewer = NEW ycl_trm_cross_ref_analisys_alv( iv_rfc_comparison = rfc_compare_destination
                                                   io_container = alv_container ).
  alv_viewer->display( result ).

ENDMODULE.

*&---------------------------------------------------------------------*
*& Module RUN_APP OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE run_analyzed_objects OUTPUT.
  alv_viewer->display_analyzed_objects( NEW cl_gui_custom_container( 'CC_ALV' ) ).
ENDMODULE.

*&---------------------------------------------------------------------*
*&      Module  EXIT_COMMAND  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit_command INPUT.

  CASE sy-ucomm.
    WHEN 'BACK' OR 'EXIT' OR 'CANCEL' OR '%EX' OR 'RW'.
      LEAVE TO SCREEN 0.
  ENDCASE.

ENDMODULE.
