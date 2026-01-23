*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations

CLASS lcl_get_object_code DEFINITION.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING iv_rfc_comparison TYPE rfcdes-rfcdest OPTIONAL.

    METHODS get_code
      IMPORTING iv_pgmid       TYPE pgmid
                iv_type        TYPE trobjtype
                iv_name        TYPE trobj_name
      RETURNING VALUE(rv_code) TYPE string.

  PRIVATE SECTION.
    TYPES ty_t_abaptxt255 TYPE STANDARD TABLE OF abaptxt255 WITH DEFAULT KEY.
    TYPES ty_t_dd03v      TYPE STANDARD TABLE OF dd03v WITH DEFAULT KEY.

    CONSTANTS c_not_supported TYPE string VALUE 'Not Supported'.

    DATA ai_rfc_comparison TYPE rfcdes-rfcdest.

    METHODS get_from_limu
      IMPORTING iv_type        TYPE trobjtype
                iv_name        TYPE vrsd-objname
      RETURNING VALUE(rv_code) TYPE string.

    METHODS get_from_r3tr
      IMPORTING iv_type        TYPE trobjtype
                iv_name        TYPE vrsd-objname
      RETURNING VALUE(rv_code) TYPE string.

    METHODS convert_abaptxt255_to_string
      IMPORTING it_data          TYPE ty_t_abaptxt255
      RETURNING VALUE(rv_string) TYPE string.

    METHODS convert_dd03v_to_string
      IMPORTING it_data          TYPE ty_t_dd03v
      RETURNING VALUE(rv_string) TYPE string.

ENDCLASS.


CLASS lcl_get_object_code IMPLEMENTATION.
  METHOD constructor.
    ai_rfc_comparison = iv_rfc_comparison.
  ENDMETHOD.

  METHOD get_code.
    CASE iv_pgmid.

      WHEN 'LIMU'.
        RETURN get_from_limu( iv_type = iv_type
                              iv_name = CONV #( iv_name ) ).

      WHEN 'R3TR'.
        RETURN get_from_r3tr( iv_type = iv_type
                              iv_name = CONV #( iv_name ) ).

      WHEN OTHERS.
        RETURN c_not_supported.

    ENDCASE.
  ENDMETHOD.

  METHOD get_from_limu.
    DATA lt_abaptxt255 TYPE STANDARD TABLE OF abaptxt255.
    DATA lt_dd03v_tab  TYPE STANDARD TABLE OF dd03v.

    CASE iv_type.

      WHEN 'CPUB'.

        CALL FUNCTION 'SVRS_GET_VERSION_CPUB_40'
          EXPORTING  destination           = ai_rfc_comparison
                     object_name           = iv_name
                     versno                = CONV vrsd-versno( '00000' )
          TABLES     psource               = lt_abaptxt255
          EXCEPTIONS no_version            = 1
                     system_failure        = 2
                     communication_failure = 3
                     OTHERS                = 4.

        RETURN convert_abaptxt255_to_string( lt_abaptxt255 ).

      WHEN 'CPRI'.

        CALL FUNCTION 'SVRS_GET_VERSION_CPRI_40'
          EXPORTING  destination           = ai_rfc_comparison
                     object_name           = iv_name
                     versno                = CONV vrsd-versno( '00000' )
          TABLES     psource               = lt_abaptxt255
          EXCEPTIONS no_version            = 1
                     system_failure        = 2
                     communication_failure = 3
                     OTHERS                = 4.

        RETURN convert_abaptxt255_to_string( lt_abaptxt255 ).

      WHEN 'CPRO'.

        CALL FUNCTION 'SVRS_GET_VERSION_CPRO_40'
          EXPORTING  destination           = ai_rfc_comparison
                     object_name           = iv_name
                     versno                = CONV vrsd-versno( '00000' )
          TABLES     psource               = lt_abaptxt255
          EXCEPTIONS no_version            = 1
                     system_failure        = 2
                     communication_failure = 3
                     OTHERS                = 4.

        RETURN convert_abaptxt255_to_string( lt_abaptxt255 ).

      WHEN 'METH'.

        CALL FUNCTION 'SVRS_GET_VERSION_METH_40'
          EXPORTING  destination           = ai_rfc_comparison
                     object_name           = iv_name
                     versno                = CONV vrsd-versno( '00000' )
          TABLES     repos_tab             = lt_abaptxt255
          EXCEPTIONS no_version            = 1
                     system_failure        = 2
                     communication_failure = 3
                     OTHERS                = 4.

        RETURN convert_abaptxt255_to_string( lt_abaptxt255 ).

      WHEN 'CINC'.

        CALL FUNCTION 'SVRS_GET_VERSION_CINC_40'
          EXPORTING  destination           = ai_rfc_comparison
                     object_name           = iv_name
                     versno                = CONV vrsd-versno( '00000' )
          TABLES     repos_tab             = lt_abaptxt255
          EXCEPTIONS no_version            = 1
                     system_failure        = 2
                     communication_failure = 3
                     OTHERS                = 4.

        RETURN convert_abaptxt255_to_string( lt_abaptxt255 ).

      WHEN 'TABD'.

        CALL FUNCTION 'SVRS_GET_VERSION_TABD_40'
          EXPORTING  destination           = ai_rfc_comparison
                     object_name           = iv_name
                     versno                = CONV vrsd-versno( '00000' )
          TABLES     dd03v_tab             = lt_dd03v_tab
          EXCEPTIONS no_version            = 1
                     system_failure        = 2
                     communication_failure = 3
                     OTHERS                = 4.

        RETURN convert_dd03v_to_string( lt_dd03v_tab ).


      WHEN 'REPS'.

        CALL FUNCTION 'SVRS_GET_VERSION_REPS_40'
          EXPORTING  destination           = ai_rfc_comparison
                     object_name           = iv_name
                     versno                = CONV vrsd-versno( '00000' )
          TABLES     REPOS_TAB             = lt_abaptxt255
          EXCEPTIONS no_version            = 1
                     system_failure        = 2
                     communication_failure = 3
                     OTHERS                = 4.

        RETURN convert_abaptxt255_to_string( lt_abaptxt255 ).

      WHEN OTHERS.
        RETURN c_not_supported.
    ENDCASE.
  ENDMETHOD.

  METHOD get_from_r3tr.
    DATA lt_dppool_abaptxt255 TYPE STANDARD TABLE OF abaptxt255.
    DATA lt_abaptxt255        TYPE STANDARD TABLE OF abaptxt255.

    CASE iv_type.

      WHEN 'INTF'.

        CALL FUNCTION 'SVRS_GET_VERSION_INTF_40'
          EXPORTING  destination           = ai_rfc_comparison
                     object_name           = iv_name
                     versno                = CONV vrsd-versno( '00000' )
          TABLES     ppool_source          = lt_dppool_abaptxt255
                     psource               = lt_abaptxt255
          EXCEPTIONS no_version            = 1
                     system_failure        = 2
                     communication_failure = 3
                     OTHERS                = 4.

        RETURN convert_abaptxt255_to_string( lt_abaptxt255 ).

      WHEN OTHERS.
        RETURN c_not_supported.
    ENDCASE.
  ENDMETHOD.

  METHOD convert_abaptxt255_to_string.
    LOOP AT it_data ASSIGNING FIELD-SYMBOL(<lv_string>).
      IF rv_string IS INITIAL.
        rv_string = <lv_string>-line.
        CONTINUE.
      ENDIF.
      rv_string = |{ rv_string }{ cl_abap_char_utilities=>cr_lf }{ <lv_string>-line }|.
    ENDLOOP.
  ENDMETHOD.

  METHOD convert_dd03v_to_string.
    LOOP AT it_data ASSIGNING FIELD-SYMBOL(<ls_data>).
      FINAL(lv_string_line) = |{ <ls_data>-fieldname } -- { <ls_data>-rollname }|.

      IF rv_string IS INITIAL.
        rv_string = lv_string_line.
        CONTINUE.
      ENDIF.
      rv_string = |{ rv_string }{ cl_abap_char_utilities=>cr_lf }{ lv_string_line }|.

    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
