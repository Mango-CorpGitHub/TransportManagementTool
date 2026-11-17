FUNCTION ytrm_fm_cross_ref_descr_atrb.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  TABLES
*"      ATTRIBUTES TYPE  YTRM_T_DESCR_ATRB
*"      RESULT TYPE  YTRM_T_DESCR_ATRB_RESULT
*"----------------------------------------------------------------------
  result[] = NEW ycl_trm_xref_attribute_descr( )->run( attributes[] ).

ENDFUNCTION.
