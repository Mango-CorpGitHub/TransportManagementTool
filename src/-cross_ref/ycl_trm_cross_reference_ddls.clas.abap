CLASS ycl_trm_cross_reference_ddls DEFINITION
  PUBLIC
  INHERITING FROM ycl_trm_cross_ref FINAL
  CREATE PRIVATE
  GLOBAL FRIENDS ycl_trm_cross_ref.

  PUBLIC SECTION.
    METHODS yif_trm_cross_reference~compare REDEFINITION.
    METHODS yif_trm_cross_reference~exists  REDEFINITION.

    METHODS describe
      IMPORTING iv_rfc_destination    TYPE rfcdes-rfcdest OPTIONAL
      RETURNING VALUE(rs_description) TYPE ycl_trm_cross_ref_describe_obj=>ty_s_ddls_desription
      RAISING   ycx_trm_transport_request.

  PROTECTED SECTION.

  PRIVATE SECTION.

ENDCLASS.


CLASS ycl_trm_cross_reference_ddls IMPLEMENTATION.
  METHOD yif_trm_cross_reference~compare.
    TRY.
        FINAL(lt_current_system_ddls_fields) = describe( )-fields.
      CATCH ycx_trm_transport_request.
    ENDTRY.

    TRY.
        FINAL(lt_dest_system_ddls_fields) = describe( iv_rfc_destination )-fields.
      CATCH ycx_trm_transport_request.
    ENDTRY.

    rt_comparison = VALUE #( FOR ls_current_system_ddls IN lt_current_system_ddls_fields
                             ( status   = yif_trm_cross_reference=>c_status-only_in_source
                               severity = icon_led_yellow
                               name     = ls_current_system_ddls-element_name ) ).

    LOOP AT lt_dest_system_ddls_fields ASSIGNING FIELD-SYMBOL(<ls_dest_system_ddls>).

      ASSIGN rt_comparison[ name = <ls_dest_system_ddls>-element_name ] TO FIELD-SYMBOL(<ls_comparison>) ELSE UNASSIGN.
      IF <ls_comparison> IS ASSIGNED.

        <ls_comparison>-status   = yif_trm_cross_reference=>c_status-exist_in_destination.
        <ls_comparison>-severity = icon_led_green.
        CONTINUE.

      ENDIF.

      " No existe en origen
      INSERT VALUE yif_trm_cross_reference=>ty_s_comparison(
                       severity = icon_led_green
                       status   = yif_trm_cross_reference=>c_status-only_in_destination
                       name     = <ls_dest_system_ddls>-element_name )
             INTO TABLE rt_comparison.

    ENDLOOP.
  ENDMETHOD.

  METHOD describe.
    RETURN ycl_trm_cross_ref_describe_obj=>new( iv_rfc_destination )->ddls(
                                                                       CONV #( cross_reference_data-reference_fragname ) ).
  ENDMETHOD.

  METHOD yif_trm_cross_reference~exists.
    TRY.
        describe( iv_rfc_destination ).
        RETURN abap_true.
      CATCH ycx_trm_transport_request.
        RETURN abap_false.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
