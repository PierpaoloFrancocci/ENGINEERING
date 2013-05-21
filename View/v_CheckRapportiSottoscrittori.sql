USE [BANZIGO_UTENTI]
GO

/****** Object:  View [dbo].[v_CheckRapportiSottoscrittori]    Script Date: 05/21/2013 12:13:20 ******/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[v_CheckRapportiSottoscrittori]'))
DROP VIEW [dbo].[v_CheckRapportiSottoscrittori]
GO

USE [BANZIGO_UTENTI]
GO

/****** Object:  View [dbo].[v_CheckRapportiSottoscrittori]    Script Date: 05/21/2013 12:13:20 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[v_CheckRapportiSottoscrittori]
AS
SELECT     ID_FILE, ID_RECORD, TXT_PROGR_MOVIMENTO, TXT_COD_CAUSALE, TXT_COD_RAPPORTO, Id_Rapporto, ID_RAPPORTO_CLASSE, 
                      SottoScrittoriByIdReport, SottoScrittoriByT100, 
                      CASE WHEN SottoScrittoriByIdReport = SottoScrittoriByT100 THEN 'CORRISPONDE' ELSE 'NON CORRISPONDE' END AS RisultatoConfronto
FROM         (SELECT     ID_FILE, ID_RECORD, TXT_PROGR_MOVIMENTO, TXT_COD_CAUSALE, TXT_COD_RAPPORTO, dbo.fn_getIdbyCode('STS_ANG_RAPPORTI', 
                                              TXT_COD_RAPPORTO) AS Id_Rapporto, ID_RAPPORTO_CLASSE, 
                                              dbo.fn_getSottoscrittoriByIdReport(dbo.fn_getIdbyCode('STS_ANG_RAPPORTI', TXT_COD_RAPPORTO)) AS SottoScrittoriByIdReport, 
                                              CASE WHEN CAST(TXT_COD_INTEST AS INT) = 0 OR
                                              TXT_COD_INTEST IS NULL THEN '' ELSE CAST(dbo.fn_getIdbyCode('STS_ANG_SOTTOSCRITTORI', TXT_COD_INTEST) AS varchar(20)) 
                                              END + CASE WHEN CAST(TXT_COD_COINTEST_1 AS INT) = 0 OR
                                              TXT_COD_COINTEST_1 IS NULL THEN '' ELSE '-' + CAST(dbo.fn_getIdbyCode('STS_ANG_SOTTOSCRITTORI', TXT_COD_COINTEST_1) 
                                              AS varchar(20)) END + CASE WHEN CAST(TXT_COD_COINTEST_2 AS INT) = 0 OR
                                              TXT_COD_COINTEST_2 IS NULL THEN '' ELSE '-' + CAST(dbo.fn_getIdbyCode('STS_ANG_SOTTOSCRITTORI', TXT_COD_COINTEST_2) 
                                              AS varchar(20)) END + CASE WHEN CAST(TXT_COD_COINTEST_3 AS INT) = 0 OR
                                              TXT_COD_COINTEST_3 IS NULL THEN '' ELSE '-' + CAST(dbo.fn_getIdbyCode('STS_ANG_SOTTOSCRITTORI', TXT_COD_COINTEST_3) 
                                              AS varchar(20)) END + CASE WHEN CAST(TXT_COD_COINTEST_4 AS INT) = 0 OR
                                              TXT_COD_COINTEST_4 IS NULL THEN '' ELSE '-' + CAST(dbo.fn_getIdbyCode('STS_ANG_SOTTOSCRITTORI', TXT_COD_COINTEST_4) 
                                              AS varchar(20)) END AS SottoScrittoriByT100
                       FROM          dbo.STS_STA_TR100) AS DATI

GO

