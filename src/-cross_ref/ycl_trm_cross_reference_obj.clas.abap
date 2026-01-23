CLASS ycl_trm_cross_reference_obj DEFINITION
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


CLASS ycl_trm_cross_reference_obj IMPLEMENTATION.
  METHOD yif_trm_cross_reference~compare.
    TRY.
        FINAL(lt_current_system_clas) = describe( ).
      CATCH ycx_trm_transport_request.
    ENDTRY.

    TRY.
        FINAL(lt_dest_system_clas) = describe( iv_rfc_destination ).
      CATCH ycx_trm_transport_request.
    ENDTRY.

    rt_comparison = VALUE #( FOR ls_current_system_clas IN lt_current_system_clas
                             ( status   = yif_trm_cross_reference=>c_status-only_in_source
                               severity = icon_led_yellow
                               name     = ls_current_system_clas-sub_object_name
                               type     = ls_current_system_clas-sub_object_type ) ).

    LOOP AT lt_dest_system_clas ASSIGNING FIELD-SYMBOL(<ls_dest_system_clas>).

      ASSIGN rt_comparison[ name = <ls_dest_system_clas>-sub_object_name
                            type = <ls_dest_system_clas>-sub_object_type ] TO FIELD-SYMBOL(<ls_comparison>) ELSE UNASSIGN.
      IF <ls_comparison> IS ASSIGNED.
        <ls_comparison>-status   = yif_trm_cross_reference=>c_status-exist_in_destination.
        <ls_comparison>-severity = icon_led_green.
        CONTINUE.
      ENDIF.

      " No existe en origen
      INSERT VALUE yif_trm_cross_reference=>ty_s_comparison(
                       severity = icon_led_green
                       status   = yif_trm_cross_reference=>c_status-only_in_destination
                       name     = <ls_dest_system_clas>-sub_object_name
                       type     = <ls_dest_system_clas>-sub_object_type )
             INTO TABLE rt_comparison.

    ENDLOOP.
  ENDMETHOD.

  METHOD describe.
    RETURN ycl_trm_cross_ref_describe_obj=>new( iv_rfc_destination )->describe(
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
