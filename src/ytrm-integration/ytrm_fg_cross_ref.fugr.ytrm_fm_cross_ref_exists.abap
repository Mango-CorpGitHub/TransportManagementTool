FUNCTION ytrm_fm_cross_ref_exists.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_PGMID) LIKE  E071-PGMID
*"     VALUE(IV_OBJECT) LIKE  E071-OBJECT
*"     VALUE(IV_OBJ_NAME) LIKE  E071-OBJ_NAME
*"  EXPORTING
*"     VALUE(E_EXIST) LIKE  STRL_PARI-FLAG
*"----------------------------------------------------------------------

  CALL FUNCTION 'TR_CHECK_EXIST'
    EXPORTING
      iv_pgmid             = iv_pgmid
      iv_object            = iv_object
      iv_obj_name          = iv_obj_name
*     IS_TADIR             = ' '
    IMPORTING
      e_exist              = e_exist
    EXCEPTIONS
      tr_no_check_function = 1
      OTHERS               = 2.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.

ENDFUNCTION.
