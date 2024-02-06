@AbapCatalog.sqlViewName: 'YITRANSPREQOBJK'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Transport Request Object Customizing'
define view YI_TRANSPORTREQUESTOBJECTCUSTO
  as select from e071k
{

  key trkorr     as TransportRequestId,
  key as4pos     as TransportRequestPosition,
  key pgmid      as ObjectId,
  key object     as ObjectType,
  key objname    as ObjectName,
      mastertype as MasterType,
      mastername as MasterName,
      viewname   as ViewName,
      //      OBJFUNC     as Object
      tabkey     as TabKey,
      sortflag   as SortFlag,
      flag       as Flag,
      lang       as Language,
      activity   as Activity
}
