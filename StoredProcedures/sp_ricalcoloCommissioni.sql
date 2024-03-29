USE [BANZIGO_UTENTI]
GO
/****** Object:  StoredProcedure [dbo].[sp_ricalcoloCommissioni]    Script Date: 05/21/2013 12:07:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[sp_ricalcoloCommissioni]

	@p_id_movimento int	
	, @p_id_rapporto_classe int
	, @p_id_file int
	, @p_id_sgr int
	, @i int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SET NOCOUNT ON;
	
	declare @ret_sp_writelog int
	declare @p_procedura varchar(200)
	declare @p_trace_code varchar(20)
	declare @p_trace_desc varchar(500)
	declare @result int  
	declare @imp_commissione numeric(15,2)
	declare @id_iniziativa_commissioni int
	declare @perc_sconto numeric (7,6)


    set @perc_sconto = 0
	set @result = 0
	set @imp_commissione = 0
	set @p_procedura = 'RICALCOLO COMMISSIONI';
	set @p_trace_desc = 'RICALCOLO COMMISSIONI per id movimento ' +  cast(@p_id_movimento as varchar(20));
	EXECUTE  @ret_sp_writelog = sp_WriteSysLog 1,@p_procedura,'0',@p_trace_desc,null, '',null

	begin transaction 
		begin try 
			print '========================================================'
			PRINT 'RICALCOLO COMMISSIONI per id movimento ' +  cast(@p_id_movimento as varchar(20));
			print '========================================================'

			SELECT @id_iniziativa_commissioni = ISNULL(ID_INIZIATIVA_COMMISSIONI, 0) 
			FROM STS_STA_MOVIMENTI_PROVVISORI
			WHERE ID_MOVIMENTO = @p_id_movimento

			if (@id_iniziativa_commissioni <> 0)
				SELECT @perc_sconto = ISNULL(PRC_SCONTO, 0) 
				FROM STS_ANG_INIZIATIVE_COMMISSIONI 
				WHERE ID_INIZIATIVA_COMMISSIONI = @id_iniziativa_commissioni

            PRINT @p_id_rapporto_classe
            
            
            declare @ValueOut SQL_VARIANT
			declare @IdStato_Calcolato int
			declare @IdStato_Confermato int
			declare @IdStato_Avvalorato int
			
			EXEC sp_GetGlobalVariableValue 'gStatoRecord_CALCOLATO' ,@ValueOut output
			set @IdStato_Calcolato=cast(@ValueOut as int)
			
			EXEC sp_GetGlobalVariableValue 'gStatoRecord_CONFERMATO' , @ValueOut output
			set @IdStato_Confermato=cast(@ValueOut as int)
			
			EXEC sp_GetGlobalVariableValue 'gStatoRecord_AVVALORATO' , @ValueOut output
			set @IdStato_Avvalorato=cast(@ValueOut as int)
			
			CREATE TABLE #MOVIMENTI (
				ID_MOVIMENTO	int
				, DTA_REGISTRAZIONE	datetime
				, TXT_PROGR_GENERALE	varchar(9)
				, NUM_MANDATO	varchar(15)
				, DTA_VALUTA	datetime
				, IMP_VALORE_QUOTA_EUR	numeric(18, 2)
				, IMP_LORDO	numeric(18, 2)
				, NUM_QUOTE	decimal(18, 7)
				, COD_CAUSALE	char(2)
				, DTA_ORDINE	datetime
				, ID_DIVISA	int
				, IMP_RATA	numeric(15, 2)
				, IMP_NETTO	numeric(18, 2)
				, ID_WRK_PROGRAMMA_VERSAMENTO INT
				, ID_PROGRAMMA_VERSAMENTO	INT				
				, COD_STATO_LAVORAZIONE	varchar(3)
				, ID_RECORD	int
				, ID_FILE	int
				, ID_INIZIATIVA_COMMISSIONI	int
				, IMP_LORDO_COMMISSIONI	numeric(15, 2)
				, IMP_NETTO_COMMISSIONI	int
				, IMP_LORDO_SPESE	numeric(15, 2)
				, IMP_NETTO_SPESE	numeric(15, 2)
				, ID_RAPPORTO_CLASSE	int
				, IMP_GLOBALE	numeric(12, 2)
				, DTA_MODIFICA	datetime
				, ID_USER	varchar(50)	
				, COD_FILE_OUT varchar(50)
				, NUM_CERTIFICATO int
				, TIPO_PAGAMENTO char(1)
				, COD_ABI_COLLOCATORE varchar(5)
				, COD_CAB_COLLOCATORE varchar(5)
				, IMP_ADDEBITATO numeric(15, 2)
				, NUM_DOMANDA int
				, DTA_RICEVIMENTO_ORDINE datetime
				, DTA_REGOLAMENTO datetime
			)
			
			Print 'INSERT INTO #MOVIMENTI'
			INSERT INTO #MOVIMENTI (
                ID_MOVIMENTO	
				, DTA_REGISTRAZIONE
				, TXT_PROGR_GENERALE	
				, NUM_MANDATO	
				, DTA_VALUTA	
				, IMP_VALORE_QUOTA_EUR	
				, IMP_LORDO	
				, NUM_QUOTE	
				, COD_CAUSALE	
				, DTA_ORDINE	
				, ID_DIVISA	
				, IMP_RATA	 
				, IMP_NETTO	
				, ID_WRK_PROGRAMMA_VERSAMENTO 				
				, ID_PROGRAMMA_VERSAMENTO				
				, COD_STATO_LAVORAZIONE	
				, ID_RECORD	
				, ID_FILE	
				, ID_INIZIATIVA_COMMISSIONI	
				, IMP_LORDO_COMMISSIONI	
				, IMP_NETTO_COMMISSIONI	
				, IMP_LORDO_SPESE	
				, IMP_NETTO_SPESE	
				, ID_RAPPORTO_CLASSE	
				, IMP_GLOBALE	
				, DTA_MODIFICA	
				, ID_USER	
				, COD_FILE_OUT
				, NUM_CERTIFICATO
				, TIPO_PAGAMENTO
				, COD_ABI_COLLOCATORE
				, COD_CAB_COLLOCATORE
				, IMP_ADDEBITATO 
				, NUM_DOMANDA
				, DTA_RICEVIMENTO_ORDINE
				, DTA_REGOLAMENTO
			)
			SELECT SMP.* FROM STS_STA_MOVIMENTI_PROVVISORI SMP
				--inner join dbo.fn_getDaticonErrori(@p_id_file ) DE
				--	on DE.ID_FILE=SMP.ID_FILE   and DE.ID_RECORD=SMP.ID_RECORD
				inner join STS_STA_INFO_RECORD SIR
					on SIR.ID_RECORD =SMP.ID_RECORD
			WHERE SIR.COD_TIPO_RECORD='100'
			and ID_RAPPORTO_CLASSE = @p_id_rapporto_classe	
			AND COD_STATO_LAVORAZIONE = 'LAV'		
			AND COD_CAUSALE = 'SO'
			AND (
					SIR.ID_STATO_RECORD=@IdStato_Calcolato 
					or SIR.ID_STATO_RECORD=@IdStato_Confermato 
					or SIR.ID_STATO_RECORD=@IdStato_Avvalorato 
				)					
			--DESC_STATO_RECORD <>dbo.fn_GetValueDatiGenerici('SRC','ANN')
			--AND ID_FILE <> @p_id_file
			--AND ID_MOVIMENTO <> @p_id_movimento 
			AND 
			(
				SMP.ID_INIZIATIVA_COMMISSIONI=0 
				OR				
				SMP.ID_INIZIATIVA_COMMISSIONI IN 
				(
					SELECT ID_INIZIATIVA_COMMISSIONI
					FROM STS_ANG_INIZIATIVE_COMMISSIONI 
					WHERE PRC_SCONTO=0
				)				
			)
			
	
			

			print 'OK INSERT INTO #MOVIMENTI'
			
			declare @p_id_file_curs int 
			declare @p_user varchar(200)
			declare @imp_tot_curs numeric (18,2)
			declare @imp_tot numeric (18,2)
			declare @imp_netto numeric (18,2)
			declare @imp_netto_curs numeric (18,2)
			declare @id_rapporto_classe_curs int
			
			set @imp_tot=0
			
            declare @id_movimento_curs int
			declare mov_cursor_@i CURSOR FOR SELECT ID_MOVIMENTO FROM #MOVIMENTI
			OPEN mov_cursor_@i
			FETCH NEXT FROM mov_cursor_@i INTO @id_movimento_curs	 
			WHILE @@FETCH_STATUS = 0
			BEGIN
				
				print '========================================================'
				print 'RICALCOLO COMMISSIONI  -- @id_movimento_curs	' +cast(@id_movimento_curs	  as varchar(20))
				print '========================================================'
				
				SELECT @p_id_file_curs = ID_FILE ,
						@id_rapporto_classe_curs = ID_RAPPORTO_CLASSE ,
						@imp_tot_curs = IMP_LORDO ,
						@p_user = ID_USER ,
						@imp_netto_curs = IMP_NETTO_COMMISSIONI 
					FROM #MOVIMENTI 
					WHERE ID_MOVIMENTO = @id_movimento_curs
				
				print 'BEGIN sp_calcoloCommissioni'
				set @imp_tot =(select sum(IMP_LORDO) from #MOVIMENTI)
				--exec @imp_tot=sp_calcoloImpTotale @id_movimento_curs, 0
				print '		@imp_netto_curs '+cast(@imp_netto_curs as varchar(20))
				print '		@imp_tot_curs '+cast(@imp_tot_curs  as varchar(20))
				print '		@imp_tot '+cast(@imp_tot  as varchar(20))
				exec @imp_netto = [sp_calcoloCommissioni] 
					@id_movimento_curs 
					, @p_id_sgr
					, @p_user 
					, @id_rapporto_classe_curs 
					, @p_id_file_curs 
					, @imp_tot  
					, @i
					, 0	
				print '		@imp_netto_curs '+cast(@imp_netto  as varchar(20))
				print 'END sp_calcoloCommissioni'
					
					
			FETCH NEXT FROM mov_cursor_@i INTO @id_movimento_curs	 
			END--fine ciclo
			CLOSE mov_cursor_@i;
			DEALLOCATE mov_cursor_@i;	
			DROP TABLE #MOVIMENTI
		
			--SELECT 'STS_STA_MOVIMENTI_PROVVISORI DOPO RICALCOLO COMMISSIONI'
			--SELECT * FROM STS_STA_MOVIMENTI_PROVVISORI
			--WHERE ID_FILE = @p_id_file
		
		end try
		begin catch
			set @result	= -1;
			declare @ErrorMessage NVARCHAR(4000);
			declare @ErrorSeverity INT;
			declare @ErrorState INT;
			select @ErrorMessage = ERROR_MESSAGE(),	@ErrorSeverity = ERROR_SEVERITY(),	@ErrorState = ERROR_STATE();

			if @@trancount > 0
				rollback transaction
			print @ErrorMessage
			set @p_trace_desc =  'Errore ' + @ErrorMessage;
			print @p_trace_desc;								
			EXECUTE  @ret_sp_writelog = sp_WriteSysLog 0,@p_procedura,'0',@p_trace_desc,null, '',null
		
			raiserror(@ErrorMessage, @ErrorSeverity, @ErrorState)
			return @result;

		end catch	
	commit transaction 
	return @imp_commissione;
END



