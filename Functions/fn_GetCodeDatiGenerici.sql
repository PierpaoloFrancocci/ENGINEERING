USE [BANZIGO_UTENTI]
GO
/****** Object:  UserDefinedFunction [dbo].[fn_GetCodeDatiGenerici]    Script Date: 05/21/2013 12:11:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Pierpaolo Francocci
-- Create date: Settembre 2010
-- Description: Ritorna Codice della tabella DATI GENERICI dati il tipo dominio ed  ID
-- =============================================

ALTER FUNCTION [dbo].[fn_GetCodeDatiGenerici] 
(
	@COD_TIPO_DOMINIO varchar(3),
	@ID_ELEMENTO int
)
RETURNS varchar(50)
AS
BEGIN
	DECLARE @ValueTabella varchar(50)	
	
	SELECT @ValueTabella =COD_DATO FROM STS_MST_DATI_GENERICI
		WHERE ID_DOMINIO=
		(SELECT ID_TIPO_DOMINIO 
				FROM dbo.STS_MST_TIPI_DOMINI 
				WHERE COD_TIPO_DOMINIO=@COD_TIPO_DOMINIO)
		AND ID_ELEMENTO =@ID_ELEMENTO

	if @@rowcount=0
		SET @ValueTabella =''
	return @ValueTabella 
END
