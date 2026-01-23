INTERFACE yif_trm_get_obj_w_collisions
  PUBLIC .

  TYPES: BEGIN OF ty_s_collisions_with,
           tr_function        TYPE RANGE OF e070-trfunction,
           tr_status          TYPE RANGE OF e070-trstatus,
           tr_last_changed_on TYPE RANGE OF e070-as4date,
         END OF ty_s_collisions_with.

  TYPES:
    ty_r_transport_request TYPE RANGE OF string .

  TYPES:
    BEGIN OF ty_s_objects,
      pgmid    TYPE string,
      object   TYPE string,
      obj_name TYPE string,
    END OF ty_s_objects .

  TYPES:
    tyt_objects TYPE STANDARD TABLE OF ty_s_objects WITH DEFAULT KEY .

  TYPES:
    BEGIN OF ty_s_colisions,
      request  TYPE string,
      pgmid    TYPE string,
      object   TYPE string,
      obj_name TYPE string,
    END OF ty_s_colisions .

  TYPES:
    tyt_colisions TYPE STANDARD TABLE OF ty_s_colisions WITH DEFAULT KEY .


  METHODS find
    IMPORTING
      !it_objects_being_transported TYPE tyt_objects
      !ir_tr_being_transported      TYPE ty_r_transport_request
      !is_collision_with            TYPE ty_s_collisions_with
    RETURNING
      VALUE(rt_colisions)           TYPE tyt_colisions .


ENDINTERFACE.
