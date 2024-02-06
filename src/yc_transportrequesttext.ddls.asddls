@AbapCatalog.sqlViewName: 'YCTRTEXT'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Description for TR Texts'
define view YC_TRANSPORTREQUESTTEXT

  as select from e07t
{
  key trkorr  as TransportRequestId,
  key langu   as Language,
      as4text as Description
}
