USE [BANZIGO_UTENTI]
GO
/****** Object:  StoredProcedure [dbo].[sp_CheckCalcoloCommissioni]    Script Date: 05/21/2013 12:05:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[sp_CheckCalcoloCommissioni] 
(@ID_SGR int)
AS
BEGIN
--
--	dbo.fn_GetImpTotale(ID_MOVIMENTO) ImpTotale, 
--	
--	in ('SI','SA','SO')

	DECLARE @ID_MOV_Cur CURSOR 
	DECLARE @ID_MOVIMENTO int
	DECLARE @ID_RECORD int
	DECLARE @COD_CAUSALE varchar(2)
	DECLARE @RetResult numeric (18,2)
	DECLARE @fg_Beneficio bit
	DECLARE @Id_Rapporto  int

	CREATE TABLE #TempMov 
	(
		ID_MOV int,
		ID_RECORD int,
		COD_CAUSALE varchar(2),
		ImpTotale numeric (18,2),
		IdRapporto int,
		fg_Beneficio bit
	)
	--CREATE TABLE #TempImporti
	--(
	--	[ID_Movimento] int , 
	--	[Cod_Causale] varchar(2),
	--	[ID_Rapporto] int , 
	--	[IMP_LORDO] numeric (18,2) , 
	--	[TOT_PIC] numeric (18,2) ,
	--	[TOT_PAC] numeric (18,2) ,
	--	[TOT_PIC_DEF] numeric (18,2) ,
	--	[TOT] numeric (18,2) 
	--)
	CREATE TABLE #TempImporti_Coinvolti
	(
		[ID_Movimento] int , 
		[Cod_Causale] varchar(2),
		[ID_Rapporto] int , 
		[IMP_LORDO] numeric (18,2) ,
		[IMP_LORDO_Coinvolti] varchar(max),
		[TOT_PIC] numeric (18,2) ,
		[TOT_PIC_Coinvolti] varchar(max),
		[TOT_PAC] numeric (18,2) ,
		[TOT_PAC_Coinvolti] varchar(max),
		[TOT_PIC_DEF] numeric (18,2) ,
		[TOT_PIC_DEF_Coinvolti] varchar(max),
		[TOT] numeric (18,2) 
	)
	SET @ID_MOV_Cur =CURSOR FOR 
	SELECT DISTINCT ID_MOVIMENTO , ID_RECORD
	FROM STS_STA_MOVIMENTI_PROVVISORI 
	WHERE ID_FILE IN  (SELECT * FROM dbo.fn_getFilesxSGR(@ID_SGR,0))
	
	OPEN @ID_MOV_Cur 

	print 'CREATE #TempMov'

	FETCH NEXT FROM @ID_MOV_Cur 
	INTO  @ID_MOVIMENTO ,@ID_RECORD

	WHILE @@FETCH_STATUS = 0
	BEGIN

	
		print '@ID_MOVIMENTO '+cast(@ID_MOVIMENTO  as varchar(20))  			 
		exec  [dbo].[sp_calcoloImpTotale] @ID_MOVIMENTO ,0, @Id_Rapporto OUTPUT, @RetResult OUTPUT
		
		EXEC [dbo].[sp_BeneficioAccumulo] @ID_MOVIMENTO,  @fg_Beneficio OUTPUT
		
		insert into #TempImporti_Coinvolti
		exec  dbo.usp_getImporti @ID_MOVIMENTO

		select @COD_CAUSALE=COD_CAUSALE from STS_STA_MOVIMENTI_PROVVISORI WHERE ID_MOVIMENTO=@ID_MOVIMENTO
	
		
		insert into #TempMov  values (@ID_MOVIMENTO , @ID_RECORD, @COD_CAUSALE, @RetResult, @Id_Rapporto ,@fg_Beneficio )
		

		FETCH NEXT FROM @ID_MOV_Cur 
		INTO  @ID_MOVIMENTO ,@ID_RECORD
	END
	close @ID_MOV_Cur

	SELECT * FROM #TempMov
	
	SELECT * FROM #TempImporti_Coinvolti

	SELECT DE.* ,ID_MOVIMENTO,SMP.COD_CAUSALE,ID_PROGRAMMA_VERSAMENTO,
	dbo.fn_GetRapporto(DE.TXT_PROGR_MOVIMENTO, DE.ID_FILE,NULL)  IdRapporto, 
	--(SELECT COUNT(*)
	--	FROM dbo.fn_GetFondiClassiQuote(DE.TXT_PROGR_MOVIMENTO,@ID_FILE )) QuanteClassiQuota,
	--(SELECT IdClasseQuota
	--	FROM dbo.fn_GetFondiClassiQuote(DE.TXT_PROGR_MOVIMENTO,@ID_FILE )) IDCLASSEQUOTA,
			RelazioneRapportoClasse=(
				CASE 
					WHEN dbo.fn_EsisteRelRapportoClasse
						(	
							dbo.fn_GetRapporto(DE.TXT_PROGR_MOVIMENTO, DE.ID_FILE,NULL),
							(
								SELECT IdClasseQuota
								FROM dbo.fn_GetFondiClassiQuote(DE.TXT_PROGR_MOVIMENTO,DE.ID_FILE )
							)
						)=1 
						THEN 'ESISTE'
						ELSE 'NON ESISTE'
				END) ,
	T.ID_RAPPORTO_CLASSE, 
	isnull(AIC.ID_INIZIATIVA_COMMISSIONI,0) ID_INIZIATIVA_COMMISSIONI,
	ISNULL(PRC_SCONTO, 0)  PRC_SCONTO,
	TM.fg_Beneficio BeneficioDiAccumulo,
	TM.ImpTotale ,T.TXT_IMPORTO,T.TXT_IMP_GLOBALE, IMP_LORDO,IMP_RATA,IMP_NETTO,SMP.COD_STATO_LAVORAZIONE, 
	IMP_LORDO_COMMISSIONI,IMP_NETTO_COMMISSIONI,IMP_LORDO_SPESE,IMP_NETTO_SPESE 

	From dbo.fn_getDaticonErrori(@ID_SGR,NULL) DE
		inner join STS_STA_MOVIMENTI_PROVVISORI SMP
			on SMP.ID_FILE =DE.ID_FILE  and SMP.ID_RECORD=DE.ID_RECORD
		inner join #TempMov TM
			on SMP.ID_MOVIMENTO=TM.ID_MOV
		inner join STS_STA_TR100 T
			on T.ID_FILE=DE.ID_FILE AND T.ID_RECORD =DE.ID_RECORD 
		inner join STS_ANG_SGR ASGR 
			on ASGR.COD_SGR = T.TXT_COD_SOCIETA 
		left outer join STS_ANG_INIZIATIVE_COMMISSIONI AIC
			on AIC.COD_INIZIATIVA_COMMISSIONI =T.TXT_COD_INIZIATIVA 
			AND AIC.ID_SGR =ASGR.ID_SGR 

		WHERE --Controllox100 is null
		DE.TXT_TIPO_RECORD='100'
		AND (	
				SELECT TXT_COD_CAUSALE 
				FROM dbo.STS_STA_TR100
				WHERE ID_FILE=DE.ID_FILE 
				AND ID_RECORD=DE.ID_RECORD
			) in ('SI','SA','SO','RI','QC','QS','AN')

END







