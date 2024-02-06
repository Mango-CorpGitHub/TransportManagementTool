*&---------------------------------------------------------------------*
*& Include          YTRM_VERSION_TOOL_V2_TOP
*&---------------------------------------------------------------------*

DATA gt_transport_requests TYPE yif_trm_transport_request=>tab.
DATA gv_dev_backup TYPE e070-trkorr.
DATA go_log TYPE REF TO yif_trm_logger.
FIELD-SYMBOLS <lo_transport_request> TYPE REF TO yif_trm_transport_request.

SELECTION-SCREEN BEGIN OF SCREEN 0002 AS SUBSCREEN.
 SELECT-OPTIONS psel FOR gv_dev_backup no INTERVALS.
SELECTION-SCREEN END OF SCREEN 0002.
