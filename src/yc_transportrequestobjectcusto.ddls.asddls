@AbapCatalog.sqlViewName: 'YCTRANSPREQOBJK'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Transport Request Object Customizing'
define view YC_TRANSPORTREQUESTOBJECTCUSTO
as select from YI_TRANSPORTREQUESTOBJECTCUSTO
{
  key TransportRequestId,
  
  key ObjectId,
  key ObjectType,
  key ObjectName,
  key TransportRequestPosition,
      MasterType,
      MasterName,
      ViewName,
      TabKey,
      SortFlag,
      Flag,
      Language,
      Activity
}
