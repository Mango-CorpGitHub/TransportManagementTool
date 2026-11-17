CLASS ycl_trm_cross_reference_tabd DEFINITION
  PUBLIC
  INHERITING FROM ycl_trm_cross_ref FINAL
  CREATE PRIVATE
  GLOBAL FRIENDS ycl_trm_xref_reference_factory.

  PUBLIC SECTION.
    METHODS yif_trm_cross_reference~compare REDEFINITION.
    METHODS yif_trm_cross_reference~exists  REDEFINITION.

    METHODS describe
      IMPORTING iv_in_destination     TYPE abap_bool DEFAULT abap_false
      RETURNING VALUE(rs_description) TYPE yif_trm_xref_system=>ty_s_table_description
      RAISING   ycx_trm_cross_reference.

  PROTECTED SECTION.

  PRIVATE SECTION.

ENDCLASS.


CLASS ycl_trm_cross_reference_tabd IMPLEMENTATION.
  METHOD yif_trm_cross_reference~compare.
    TRY.
        FINAL(lt_current_system_tabd_fields) = describe( )-fields.
      CATCH ycx_trm_cross_reference.
    ENDTRY.

    TRY.
        FINAL(lt_dest_system_tabd_fields) = describe( iv_in_destination = abap_true )-fields.
      CATCH ycx_trm_cross_reference.
    ENDTRY.

    rt_comparison = VALUE #( FOR ls_current_system IN lt_current_system_tabd_fields
                             ( status   = yif_trm_cross_reference=>c_status-only_in_source
                               severity = icon_led_yellow
                               name     = ls_current_system-FIELDname
                               type     = ls_current_system-rollname ) ).

    LOOP AT lt_dest_system_tabd_fields ASSIGNING FIELD-SYMBOL(<ls_dest_system>).

      ASSIGN rt_comparison[ name = <ls_dest_system>-fieldname ] TO FIELD-SYMBOL(<ls_comparison>) ELSE UNASSIGN.
      IF <ls_comparison> IS ASSIGNED.

        IF <ls_comparison>-type = <ls_dest_system>-rollname.
          <ls_comparison>-status   = yif_trm_cross_reference=>c_status-equal_in_destination.
          <ls_comparison>-severity = icon_led_green.
          CONTINUE.
        ENDIF.

        <ls_comparison>-status   = yif_trm_cross_reference=>c_status-different_in_destination.
        <ls_comparison>-severity = icon_led_yellow.
        CONTINUE.

      ENDIF.

      " No existe en origen
      INSERT VALUE yif_trm_cross_reference=>ty_s_comparison(
                       severity = icon_led_green
                       status   = yif_trm_cross_reference=>c_status-only_in_destination
                       name     = <ls_dest_system>-fieldname
                       type     = <ls_dest_system>-rollname )
             INTO TABLE rt_comparison.

    ENDLOOP.
  ENDMETHOD.

  METHOD describe.
    RETURN system( iv_in_destination )->describe_table(
                                                                       CONV #( cross_reference_data-reference_fragname ) ).
  ENDMETHOD.

  METHOD yif_trm_cross_reference~exists.
    TRY.
        describe( iv_in_destination = abap_true ).
        RETURN abap_true.
      CATCH ycx_trm_cross_reference.
        RETURN abap_false.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
