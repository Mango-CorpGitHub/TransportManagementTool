CLASS ycl_trm_cross_ref_obj_part DEFINITION
  PUBLIC
  INHERITING FROM ycl_trm_cross_ref FINAL
  CREATE PRIVATE
  GLOBAL FRIENDS ycl_trm_cross_ref.

  PUBLIC SECTION.
    METHODS yif_trm_cross_reference~compare REDEFINITION.
    METHODS yif_trm_cross_reference~exists  REDEFINITION.

    METHODS describe
      IMPORTING iv_rfc_destination    TYPE rfcdes-rfcdest OPTIONAL
      RETURNING VALUE(rt_description) TYPE ycl_trm_cross_ref_describe_obj=>ty_t_description
      RAISING   ycx_trm_transport_request.

  PROTECTED SECTION.

  PRIVATE SECTION.

ENDCLASS.


CLASS ycl_trm_cross_ref_obj_part IMPLEMENTATION.
  METHOD yif_trm_cross_reference~compare.

    TRY.
        FINAL(lt_current_system_clas_part) = describe( ).
      CATCH ycx_trm_transport_request.
    ENDTRY.

    TRY.
        FINAL(lt_dest_system_clas_part) = describe( iv_rfc_destination ).
      CATCH ycx_trm_transport_request.
    ENDTRY.

    rt_comparison = VALUE #( FOR ls_current_system_clas_part IN lt_current_system_clas_part
                             ( status   = yif_trm_cross_reference=>c_status-only_in_source
                               severity = icon_led_yellow
                               name     = ls_current_system_clas_part-sub_object_name
                               type     = ls_current_system_clas_part-sub_object_type ) ).

    LOOP AT lt_dest_system_clas_part ASSIGNING FIELD-SYMBOL(<ls_dest_system_clas_part>).

      ASSIGN rt_comparison[ name = <ls_dest_system_clas_part>-sub_object_name
                            type = <ls_dest_system_clas_part>-sub_object_type ] TO FIELD-SYMBOL(<ls_comparison>) ELSE UNASSIGN.
      IF <ls_comparison> IS ASSIGNED.
        <ls_comparison>-status   = yif_trm_cross_reference=>c_status-exist_in_destination.
        <ls_comparison>-severity = icon_led_green.
        CONTINUE.
      ENDIF.

      " No existe en origen
      INSERT VALUE yif_trm_cross_reference=>ty_s_comparison(
                       severity = icon_led_green
                       status   = yif_trm_cross_reference=>c_status-only_in_destination
                       name     = <ls_dest_system_clas_part>-sub_object_name
                       type     = <ls_dest_system_clas_part>-sub_object_type )
             INTO TABLE rt_comparison.

    ENDLOOP.

  ENDMETHOD.

  METHOD describe.

    CASE cross_reference_data-reference_fragment.

      WHEN 'CPUB'.

        RETURN ycl_trm_cross_ref_describe_obj=>new( iv_rfc_destination )->public(
            CONV #( cross_reference_data-reference_fragname ) ).

      WHEN 'CPRO'.

        RETURN ycl_trm_cross_ref_describe_obj=>new( iv_rfc_destination )->protected(
            CONV #( cross_reference_data-reference_fragname ) ).

      WHEN 'CPRI'.
        RETURN ycl_trm_cross_ref_describe_obj=>new( iv_rfc_destination )->private(
            CONV #( cross_reference_data-reference_fragname ) ).

    ENDCASE.

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
