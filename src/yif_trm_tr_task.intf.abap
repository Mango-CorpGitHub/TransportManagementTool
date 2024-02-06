INTERFACE yif_trm_tr_task
  PUBLIC .

  INTERFACES yif_trm_transport_request .

  ALIASES get_category
    FOR yif_trm_transport_request~get_category .
  ALIASES get_code
    FOR yif_trm_transport_request~get_code .
  ALIASES get_description
    FOR yif_trm_transport_request~get_description .
  ALIASES get_owner
    FOR yif_trm_transport_request~get_owner .
  ALIASES get_status
    FOR yif_trm_transport_request~get_status .
  ALIASES get_type
    FOR yif_trm_transport_request~get_type .
  ALIASES get_entries
    FOR yif_trm_transport_request~get_entries.
  ALIASES release
    FOR yif_trm_transport_request~release .
  ALIASES delete_entry
    FOR yif_trm_transport_request~delete_entry.

  TYPES:
    tab TYPE STANDARD TABLE OF REF TO yif_trm_tr_task WITH DEFAULT KEY .

  CONSTANTS:
    BEGIN OF type,
      development  TYPE trfunction VALUE 'S',
      repair       TYPE trfunction VALUE 'R',
      unclassified TYPE trfunction VALUE 'X',
    END OF type .

  METHODS get_transport_request
    RETURNING
      VALUE(re_transport_request) TYPE REF TO yif_trm_transport_request .

ENDINTERFACE.
