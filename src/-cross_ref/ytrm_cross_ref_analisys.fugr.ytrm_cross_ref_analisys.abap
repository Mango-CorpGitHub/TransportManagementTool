FUNCTION ytrm_cross_ref_analisys.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(IV_RFC_COMPARE_DESTINATION) TYPE  RFCDEST
*"  TABLES
*"      IT_OBJECTS STRUCTURE  CNVCDMCCTS_OBJECTS_SET
*"----------------------------------------------------------------------
  DATA lv_answer TYPE c LENGTH 1.

  CLEAR alv_viewer.

  lt_objs = it_objects[].
  rfc_compare_destination = iv_rfc_compare_destination.

  TRY.
      result = NEW ycl_trm_cross_ref_analisys( rfc_compare_destination )->run( lt_objs ).
    CATCH ycx_trm_cross_reference INTO DATA(lox_error).
      lox_error->logger->display( ).
      RETURN.
  ENDTRY.

  IF result IS INITIAL.

    CLEAR lv_answer.
    CALL FUNCTION 'POPUP_TO_CONFIRM_STEP'
      EXPORTING
*                defaultoption  = 'Y'              " Positioning the cursor on answer yes or no
                textline1      = |No dependencies found|                 " first line of dialog box
                textline2      = |Update the Navigation Index and perform the analisys again?|            " second line of dialog box
                titel          = |Update Navigation Index|                 " Title line of dialog box
*                start_column   = 25               " Start column of the dialog box
*                start_row      = 6                " Start line of the dialog box
                cancel_display = abap_false             " Display cancel button
      IMPORTING answer         = lv_answer.                 " selected answer of end user
    IF lv_answer <> 'J'.
      RETURN.
    ENDIF.

    TRY.
        NEW ycl_trm_update_navigation_indx( )->update( lt_objs ).
        result = NEW ycl_trm_cross_ref_analisys( rfc_compare_destination )->run( lt_objs ).
      CATCH ycx_trm_cross_reference INTO lox_error.
        lox_error->logger->display( ).
        RETURN.
    ENDTRY.

    IF result IS INITIAL.
      FINAL(lo_log) = ycl_trm_logger=>new( ).
      lo_log->add_text( im_text = 'No dependencies found'
                        im_type = 'S' ).
      lo_log->display( ).
      RETURN.
    ENDIF.

  ENDIF.

  CALL SCREEN 300 STARTING AT 15 15 ENDING AT 250 60.

  alv_viewer->free( ).
  alv_container->free( ).
ENDFUNCTION.
