USE [BANZIGO_UTENTI]
GO
/****** Object:  UserDefinedFunction [dbo].[fn_getSommarioStati]    Script Date: 05/21/2013 12:10:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER FUNCTION [dbo].[fn_getSommarioStati]
(	
	@ID_FILE int
)
RETURNS 
@ResultTable TABLE
(

[DESC_STATO_RECORD] varchar(20),
[NumerositaStato] int,
[StatiErrore] int,
[StatiBlocco] int
) 
AS
begin 
	INSERT INTO @ResultTable 
	SELECT  
	DESC_STATO_RECORD,count(*) as NumerositaStato, 
	ISNULL((
		SELECT count(*) 
		From dbo.fn_getDaticonErrori(NULL,@ID_FILE)
		GROUP BY Errori ,DESC_STATO_RECORD

		HAVING Errori ='ERRORE'
		AND DESC_STATO_RECORD=DE.DESC_STATO_RECORD
		AND (
				DESC_STATO_RECORD=DE.DESC_STATO_RECORD 
					OR 
				(DESC_STATO_RECORD IS NULL AND DE.DESC_STATO_RECORD IS NULL)
			)
	),0) AS StatiErrore,
	ISNULL((
		SELECT count(*) 
		From dbo.fn_getDaticonErrori(NULL,@ID_FILE)
		GROUP BY Blocchi ,DESC_STATO_RECORD
		HAVING Blocchi='BLOCCO'
		AND (
				DESC_STATO_RECORD=DE.DESC_STATO_RECORD 
					OR 
				(DESC_STATO_RECORD IS NULL AND DE.DESC_STATO_RECORD IS NULL)
			)
	),0) AS StatiBlocco
		
	From dbo.fn_getDaticonErrori(NULL,@ID_FILE) DE
	GROUP BY DESC_STATO_RECORD
	
	return

end

