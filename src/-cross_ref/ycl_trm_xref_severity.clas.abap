"! Severity of the status of a cross reference, as icon and as text
CLASS ycl_trm_xref_severity DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CONSTANTS: BEGIN OF c_text,
                 red      TYPE string VALUE `RED`,
                 yellow   TYPE string VALUE `YELLOW`,
                 green    TYPE string VALUE `GREEN`,
                 checked  TYPE string VALUE `CHECKED`,
                 internal TYPE string VALUE `INTERNAL`,
               END OF c_text.

    "! Severity icon of a cross reference status
    METHODS of_status
      IMPORTING iv_status      TYPE yif_trm_cross_reference=>ty_e_status
      RETURNING VALUE(rv_icon) TYPE icon-name.

    "! Text of a severity icon; empty if the icon is not a severity
    METHODS to_text
      IMPORTING iv_icon        TYPE icon-name
      RETURNING VALUE(rv_text) TYPE string.

ENDCLASS.



CLASS ycl_trm_xref_severity IMPLEMENTATION.

  METHOD of_status.
    rv_icon = SWITCH #( iv_status
                        WHEN yif_trm_cross_reference=>c_status-also_in_transport_request     THEN icon_checked
                        WHEN yif_trm_cross_reference=>c_status-different_in_destination      THEN icon_led_yellow
                        WHEN yif_trm_cross_reference=>c_status-method_definition_dif_in_dest THEN icon_led_yellow
                        WHEN yif_trm_cross_reference=>c_status-method_def_dif_in_dest_w_err  THEN icon_led_red
                        WHEN yif_trm_cross_reference=>c_status-equal_in_destination          THEN icon_led_green
                        WHEN yif_trm_cross_reference=>c_status-exist_in_destination          THEN icon_led_green
                        WHEN yif_trm_cross_reference=>c_status-different_but_not_relevant    THEN icon_led_green
                        WHEN yif_trm_cross_reference=>c_status-only_in_source                THEN icon_led_red
                        WHEN yif_trm_cross_reference=>c_status-different                     THEN icon_led_red
                        WHEN yif_trm_cross_reference=>c_status-definition_missing            THEN icon_led_red
                        WHEN yif_trm_cross_reference=>c_status-definition_also_in_trans_req  THEN icon_led_green
                        WHEN yif_trm_cross_reference=>c_status-sap_reference                 THEN icon_checked
                        WHEN yif_trm_cross_reference=>c_status-subobject_not_assigned        THEN icon_abap
                        WHEN yif_trm_cross_reference=>c_status-to_delete                     THEN icon_abap ).
  ENDMETHOD.


  METHOD to_text.
    rv_text = SWITCH #( iv_icon
                        WHEN icon_led_red    THEN c_text-red
                        WHEN icon_led_yellow THEN c_text-yellow
                        WHEN icon_led_green  THEN c_text-green
                        WHEN icon_checked    THEN c_text-checked
                        WHEN icon_abap       THEN c_text-internal ).
  ENDMETHOD.

ENDCLASS.
