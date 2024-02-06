interface YIF_TRM_TRANSPORT_REQUEST
  public .


  types TY_E_SYSTEM type CHAR01 .
  types:
    BEGIN OF typ_s_code,
      code TYPE trkorr,
    END OF typ_s_code .
  types:
    typ_t_code TYPE STANDARD TABLE OF typ_s_code WITH KEY primary_key COMPONENTS code
                                                      WITH UNIQUE SORTED KEY sorted_key COMPONENTS code .
  types:
    tab TYPE STANDARD TABLE OF REF TO yif_trm_transport_request WITH DEFAULT KEY .

  constants:
    BEGIN OF type,
      workbench   TYPE trfunction VALUE 'K',
      customizing TYPE trfunction VALUE 'W',
      toc         TYPE trfunction VALUE 'T',
    END OF type .
  constants:
    BEGIN OF status,
      modifiable                     TYPE trstatus VALUE 'D',
      modifiable_protected           TYPE trstatus VALUE 'L',
      release_started                TYPE trstatus VALUE 'O',
      release                        TYPE trstatus VALUE 'R',
      release_with_import_protection TYPE trstatus VALUE 'N',
    END OF status .
  constants:
    BEGIN OF system,
      development TYPE ty_e_system VALUE 'D',
      quality     TYPE ty_e_system VALUE 'Q',
      production  TYPE ty_e_system VALUE 'P',
    END OF system .
  constants MESSAGE_CLASS type MSGID value 'YTRM' ##NO_TEXT.

  methods GET_CODE
    returning
      value(RE_CODE) type TRKORR .
  methods RELEASE
    importing
      !IM_CHECK_RELEASED type ABAP_BOOL default ABAP_TRUE
      !IM_RELEASE_TASKS type ABAP_BOOL default ABAP_TRUE
    raising
      YCX_TRM_TRANSPORT_REQUEST .
  methods IS_RELEASED
    returning
      value(RE_IS_RELEASED) type ABAP_BOOL .
  methods ADD_OBJECTS
    importing
      !IM_T_TRANSPORT_REQUEST type YIF_TRM_TRANSPORT_REQUEST=>TAB optional
      !IM_T_E071 type E071_T optional
      !IM_T_E071K type E071K_T optional
    raising
      YCX_TRM_TRANSPORT_REQUEST .
  methods GET_DESCRIPTION
    importing
      !IM_LANGUAGE type YC_TRANSPORTREQUESTTEXT-LANGUAGE default SY-LANGU
    returning
      value(RE_DESCRIPTION) type YC_TRANSPORTREQUESTTEXT-DESCRIPTION .
  methods GET_TYPE
    returning
      value(RE_TYPE) type YC_TRANSPORTREQUEST-TRANSPORTREQUESTTYPE .
  methods GET_OWNER
    exporting
      !EX_NAME type AD_NAMTEXT
    returning
      value(RE_OWNER) type YC_TRANSPORTREQUEST-TRANSPORTREQUESTOWNER .
  methods GET_STATUS
    returning
      value(RE_STATUS) type YC_TRANSPORTREQUEST-TRANSPORTREQUESTSTATUS .
  methods GET_TARGET
    returning
      value(RE_TARGET) type YC_TRANSPORTREQUEST-TRANSPORTREQUESTTARGET .
  methods GET_CATEGORY
    returning
      value(RE_CATEGORY) type YC_TRANSPORTREQUEST-TRANSPORTREQUESTCATEGORY .
  methods GET_LAST_CHANGE_DATE
    returning
      value(RE_LAST_CHANGE_DATE) type YC_TRANSPORTREQUEST-LASTCHANGEDATE .
  methods GET_LAST_CHANGE_TIME
    returning
      value(RE_LAST_CHANGE_TIME) type YC_TRANSPORTREQUEST-LASTCHANGETIME .
  methods IS_TASK
    returning
      value(RE_IS_TASK) type ABAP_BOOL .
  methods GET_TASKS
    returning
      value(RE_T_TASK) type YIF_TRM_TR_TASK=>TAB .
  methods GET_ENTRIES
    importing
      !IM_INCLUDE_TASK_OBJECTS type ABAP_BOOL default ABAP_FALSE
    returning
      value(RE_T_ENTRIES) type YIF_TRM_TR_OBJECT=>TAB .
  methods GET_ENTRY
    importing
      !IM_POSITION type DDPOSITION
    returning
      value(RE_O_ENTRY) type ref to YIF_TRM_TR_OBJECT
    raising
      YCX_TRM_TRANSPORT_REQUEST .
  methods ADD_TO_QUEUE
    importing
      !IM_SYSTEM type TY_E_SYSTEM
    raising
      YCX_TRM_TRANSPORT_REQUEST .
  methods LOCK
    raising
      YCX_TRM_TRANSPORT_REQUEST .
  methods UNLOCK .
  methods DELETE_ENTRY
    importing
      !IM_O_ENTRY type ref to YIF_TRM_TR_OBJECT
    raising
      YCX_TRM_TRANSPORT_REQUEST .
endinterface.
