EXECUTE sp_addlinkedserver @server = N'TempCompare'
GO
EXECUTE sp_addlinkedsrvlogin @rmtsrvname = N'TempCompare'
