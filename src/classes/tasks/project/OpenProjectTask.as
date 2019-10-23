package classes.tasks.project
{
	import com.audioengine.sequencer.events.SequencerEvent;
	import com.serialization.Serialize;
	import com.thread.SimpleTask;
	import com.thread.events.TaskEvent;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.system.System;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.controls.ProgressBarMode;
	import mx.core.FlexGlobals;
	import mx.events.CloseEvent;
	
	import classes.BaseDescription;
	import classes.PaletteSample;
	import classes.SamplesPalette;
	import classes.SequencerImplementation;
	import classes.Sources;
	import classes.api.MainAPI;
	import classes.api.MainAPIImplementation;
	import classes.api.data.ProjectAccess;
	import classes.api.data.ProjectInfo;
	import classes.api.events.GetProjectEvent;
	import classes.api.events.GetUserInfoEvent;
	import classes.api.events.ProjectNameEvent;
	import classes.api.social.vk.VKApi;
	import classes.events.ChangeBPMEvent;
	import classes.events.PaletteErrorEvent;
	import classes.tasks.project.views.OpenProjectDialog;
	
	import components.library.acapellas.AcapellaAPI;
	import components.library.events.DataEvent;
	import components.library.looperman.LoopermanAPI;
	import components.managers.PopUpManager;
	import components.sequencer.VisualSequencer;
	import components.sequencer.clipboard.SampleClipboardRecord;
	import components.sequencer.events.ProjectEvent;
	
	
	public class OpenProjectTask extends SimpleTask
	{
		public static const CHECK_PROJECT_ACCESS   : int =  5;
		public static const INITIALIZE             : int = 10;
		public static const GETTING_PROJECT        : int = 20;
		public static const GETTING_SAMPLES_INFO   : int = 30;
		public static const GETTING_ACAPELLAS_INFO : int = 35;
		public static const DOWNLOADING_PALETTE    : int = 40;
		public static const DESERIALIZING          : int = 50;
		
		private var project   : ProjectTask;
		private var vs        : VisualSequencer;
		private var seq       : SequencerImplementation;
		private var palette   : SamplesPalette;
		
		public var info : ProjectInfo;
		private var projectData : XML;
		private var samplesInfo : Vector.<BaseDescription>;
		
		/**
		 * Описатели сэмплов хранятся здесь перед загрузкой 
		 */		
		private var samplesDescriptors : Array;
		/**
		 *  Описатели акапел хранятся здесь перед загрузкой 
		 */		
		private var acapellasDescriptors : Array;
		
		private var api    : MainAPIImplementation;
		private var libAPI : LoopermanAPI;
		private var acapellaAPI : AcapellaAPI;
		
		private var dialog : OpenProjectDialog;
		
		/**
		 * Время когда стартовал процесс загрузки проекта 
		 */		
		//private var startTime : int = -1;
		/**
		 * Минимальное время, в течение которого будет показан банер 
		 */		
		//private static const MIN_SHOW_ADS : int = 10000; //10 с
		
		public function OpenProjectTask( vs : VisualSequencer, project : ProjectTask, info : ProjectInfo )
		{
			super();
			this.vs = vs;
			this.project = project;
			this.info = info.clone();
			
			seq = vs.seq;
			palette = vs.seq.palette;
			
			api = MainAPI.impl;
		}
		
		/**
		 * Возвращает количество времени прошедшего с момента запуска загрузки проекта 
		 * @return 
		 * 
		 */		
		/*private function get timeElapsed() : int
		{
			return getTimer() - startTime;
		}*/
		
		public function destroy() : void
		{
			projectData = null;
			samplesInfo = null;
			api.removeAllObjectListeners( this );
		}
		
		override protected function next():void
		{
			switch( _status )
			{
				case SimpleTask.NONE :
					dialog.progress.indeterminate = true;
					dialog.progress.mode = ProgressBarMode.EVENT;
					dialog.progress.label = '';
					dialog.status.text = 'Проверка прав доступа...';
					checkProjectAccess();
					
					break;
				
				case CHECK_PROJECT_ACCESS :
					dialog.status.text = 'Открываю...';
					initProject();
					break;
				
				case INITIALIZE : 
					dialog.status.text = 'Загрузка микса...';
					getProject();
					break;
				case GETTING_PROJECT : deserializePalette( projectData );  getSamplesInfo();
					dialog.status.text = 'Поиск сэмплов микса...';
					break;
				case GETTING_SAMPLES_INFO : getAcapellasInfo();
					dialog.status.text = 'Поиск вокальных партий микса...';
					break;
				case GETTING_ACAPELLAS_INFO : 
					dialog.progress.indeterminate = false;
					dialog.progress.mode = ProgressBarMode.MANUAL;
					dialog.progress.label = '0%';
					dialog.status.text = 'Загрузка сэмплов...';
					downloadPalette();
					break;
				case DOWNLOADING_PALETTE : 
					dialog.progress.indeterminate = true;
					dialog.progress.mode = ProgressBarMode.EVENT;
					dialog.status.text = 'Секундочку...';
					dialog.progress.label = '';
					if ( errorSamples )
					{
						handleErrorSamples();
					}
					else
					{
					 callLater( deserializeProject, projectData );
					}
					break;
				case DESERIALIZING : 
						_status = SimpleTask.DONE;
						callLater( closeDialog, Alert.OK );
					    break;
				case SimpleTask.ERROR : 
					dialog.status.setStyle( 'color', 0xff0000 );
					dialog.status.text += ' - произошла ошибка';
					break;
			}
			
			super.next();
		}
		
		private function handleErrorSamples() : void
		{
			dialog.failedItems.visible = dialog.failedItems.includeInLayout = true;
			dialog.errorList.dataProvider = new ArrayCollection( errorSamples );
			dialog.progressGroup.visible = dialog.progressGroup.includeInLayout = false;
			dialog.continueGroup.visible = dialog.continueGroup.includeInLayout = true;
			dialog.openMixButton.addEventListener( MouseEvent.CLICK, onOpenMixButtonClick );
			dialog.reloadMixButton.addEventListener( MouseEvent.CLICK, onReloadMixButtonClick );
		}
		
		private function onReloadMixButtonClick( e : MouseEvent ) : void
		{
			dialog.openMixButton.removeEventListener( MouseEvent.CLICK, onOpenMixButtonClick );
			dialog.reloadMixButton.removeEventListener( MouseEvent.CLICK, onReloadMixButtonClick );
			closeDialog( Alert.NO );
		}
		
		private function onOpenMixButtonClick( e : MouseEvent ) : void
		{
			dialog.failedItems.visible = dialog.failedItems.includeInLayout = false;
			dialog.errorList.dataProvider = null;
			dialog.progressGroup.visible = dialog.progressGroup.includeInLayout = true;
			dialog.continueGroup.visible = dialog.continueGroup.includeInLayout = false;
			dialog.openMixButton.removeEventListener( MouseEvent.CLICK, onOpenMixButtonClick );
			dialog.reloadMixButton.removeEventListener( MouseEvent.CLICK, onReloadMixButtonClick );
			errorSamples = null;
			next();
		}
		
		private function onVKAPIError( data : Object ) : void
		{
			_status = SimpleTask.ERROR;
			next();
		}
		
		private function onGotInfoAboutFriends( data : Object ) : void
		{
			if ( ! data || data.length == 0 )
			{
				_status = SimpleTask.ERROR;
			}
			else if ( data[ 0 ].friend_status != 3 )
			{
				Alert.show( 'Владелец микса "' + info.name + '" разрешил открывать его только друзьям.\nИзвини, но ты не являешся другом владельца.\nОткрытие микса невозможно...', 'Ошибка открытия микса', Alert.OK, null, onCloseDialog, Assets.BROADCAST );
				_status = SimpleTask.ERROR;
			}
			
			next();
		}
		
		private function onGotUserInfo( e : GetUserInfoEvent ) : void
		{
			api.removeListener( GetUserInfoEvent.GET_USER_INFO, onGotUserInfo ); 
			
			if ( e.error )
			{
				_status = SimpleTask.ERROR;
				next();
				return;
			}
			
			//Проверяем евляются ли пользователи друзьями
			if ( VKApi.initialized )
			{
				VKApi.impl.api( 'friends.areFriends', { user_ids : e.info.netUserId }, onGotInfoAboutFriends, onVKAPIError );
			}
			else
			{
				next();
			}
		}
		
		private function checkProjectAccess() : void
		{
			_status = CHECK_PROJECT_ACCESS;
			
			//Проект никому не принадлежит (Демонстрационный пример, например)
			if ( info.owner == 0 )
			{
				next();
				return;
			}
			
			//Проект доступен 
			
			//всем
			if ( info.access == ProjectAccess.ALL )
			{
				next();
				return;
			}
			
			if ( api.userInfo.id != info.owner )
			{
				//Друзьям
				if ( info.access == ProjectAccess.FRIENDS )
				{
					//Получаем информацию о пользователе
					api.addListener( GetUserInfoEvent.GET_USER_INFO, onGotUserInfo, this );
					api.getUserInfo( info.owner );	
					
					return;
				}
				
				//Никому кроме владельца
				if ( info.access == ProjectAccess.NOBODY )
				{
					//Проект открывает кто-то другой
					
						Alert.show( 'Владелец микса "' + info.name + '" запретил открывать его другим пользователям./n Открытие микса невозможно...', 'Ошибка открытия микса', Alert.OK, null, onCloseDialog, Assets.BROADCAST );
						_status = SimpleTask.ERROR;
				}
			}
			
			next();
		}
		
		private function onNameResolved( e : ProjectNameEvent ) : void
		{
			api.removeListener( ProjectNameEvent.RESOLVE_NAME, onNameResolved );
			
			if ( e.error )
		    {
			  _status = SimpleTask.ERROR;
			  next();
		    }
		    else
		    {
			  info.name = e.name;
			  changeProject();
		    }
		}
		
		private function initProject() : void
		{
			_status = INITIALIZE;
			
			if ( info.owner != api.userInfo.id )
			{
				api.addListener( ProjectNameEvent.RESOLVE_NAME, onNameResolved, this );
				api.resolveName( info.name );
			}
			else
			{
				changeProject();
			}
		}
		
		private function onChangeProjectComplete( e : TaskEvent ) : void
		{
			//Только теперь, когда убедились что все изменения были сохранены очищаем проект
			vs.clearAll();
			//!!!!!!!
			
			project.removeEventListener( TaskEvent.COMPLETE, onChangeProjectComplete );
			next();
		}
		
		private function waitLastOperationComplete( e : TaskEvent ) : void
		{
			project.removeEventListener( TaskEvent.COMPLETE, waitLastOperationComplete );
			changeProject();
		}
		
		private function changeProject() : void
		{
			if ( project.status == SimpleTask.NONE )
			{
				project.addEventListener( TaskEvent.COMPLETE, onChangeProjectComplete );
				project.changeProject( info );	
			}
			else //Ждем пока завершится предыдущая операция
			{
				project.addEventListener( TaskEvent.COMPLETE, waitLastOperationComplete );
			}
		}
		
		private function onGetProject( e : GetProjectEvent ) : void
		{
		   api.removeListener( GetProjectEvent.GET_PROJECT, onGetProject );
		   
		   if ( e.error )
		   {
			   _status = SimpleTask.ERROR;
			   next();
			   return;
		   }
		   
		   try
		   {
			   projectData = new XML( e.data );   
		   }
		   catch( error : Error )
		   {
			   _status = SimpleTask.ERROR;
		   }
		   finally
		   {
			   next();
		   }
		}
		
		private function getProject() : void
		{
			_status = GETTING_PROJECT;
			api.addListener( GetProjectEvent.GET_PROJECT, onGetProject, this );
			api.getProject( info.id, info.owner );
		}
		
		/**
		 * Возвращает список идентификаторов семплов использованных в проекте 
		 * @param xml
		 * @return 
		 * 
		 */	    
		private function getProjectSampleIDs( xml : XML ) : Array
		{
			//Список семплов использованных в проекте
			var mSamples : Array = new Array();
			var id : String;
			
			if ( xml.channels != undefined )
			{
				for each( var channel : XML in xml.channels.elements( 'channel' ) )
				{
					if ( channel.notes != undefined )
					{
						for each( var note : XML in channel.notes.elements( 'note' ) )
						{
							/*
							  BaseDescription.correctSampleID
							  коректируем идентификатор сэмпла, если используется идентификатор старой версии
							*/
							mSamples.push( BaseDescription.correctSampleID( note.sample.@id.toString() ) );
						}
					}
				}
			}
			
			return mSamples;
		}
		
		/**
		 * Возвращает список идентификаторов использованных в палитре 
		 * @param xml
		 * @return 
		 * 
		 */		
		private function deserializePalette( xml : XML ) : void
		{
			if ( xml.palette != undefined )
			{
				var id         : String;
				var source     : String;
				
				for each( var s : XML in xml.palette.elements( 'sample' ) )
				{
					if ( s.@source == undefined )
					{
						id     = BaseDescription.extractSampleID( s.@id.toString() );
						source = BaseDescription.extractSampleSource( s.@id.toString() );
					}
					else
					{
						id     = s.@id.toString();
						source = s.@source.toString();
					}
					
					if ( source == Sources.SAMPLE_SOURCE )
					{
						if ( samplesDescriptors == null )
						{
							samplesDescriptors = new Array();
						}
						
						samplesDescriptors.push( id );
					}
					else if ( source == Sources.ACAPELLA_SOURCE )
					{
						if ( acapellasDescriptors == null )
						{
							acapellasDescriptors = new Array();
						}
						
						acapellasDescriptors.push( id );
					}
				}
			}
		}
		
		private function unsetLibApi() : void
		{
			if ( libAPI )
			{
				libAPI.removeAllObjectListeners( this );
				libAPI = null;
				samplesDescriptors = null;
			}
			
			if ( acapellaAPI )
			{
				acapellaAPI.removeAllObjectListeners( this );
				acapellaAPI = null;
				acapellasDescriptors = null;
			}
		}
		
		private function onGetSamplesInfo( e : DataEvent ) : void
		{
			unsetLibApi();
			
			if ( e.data.length > 0 )
			{
				samplesInfo = samplesInfo ? samplesInfo.concat( e.data ) : e.data;
				
				/*
				if ( ! samplesInfo )
				{
					samplesInfo = new Vector.<BaseDescription>()
				}
				
				for each( var info : Object in  e.data )
				{
					samplesInfo.push( Sources.loadFromSource( info ) );	
				}
				*/
			}
			
			next();
		}
		
		private function getSamplesInfo() : void
		{
			_status = GETTING_SAMPLES_INFO;
			
			if ( samplesDescriptors )
			{
				libAPI = new LoopermanAPI();
				libAPI.addListener( DataEvent.DATA_COMPLETE, onGetSamplesInfo, this );
				
				libAPI.getInfo( samplesDescriptors );	
			}
			else
			{
				callLater( next );
			}
		}
		
		private function getAcapellasInfo() : void
		{
			_status = GETTING_ACAPELLAS_INFO;
			
			if ( acapellasDescriptors )
			{
				acapellaAPI = new AcapellaAPI();
				acapellaAPI.addListener( DataEvent.DATA_COMPLETE, onGetSamplesInfo, this );
				
				acapellaAPI.getInfo( acapellasDescriptors );	
			}
			else
			{
				callLater( next );
			}
		}
		
		private function unsetPaletteListeners() : void
		{
			palette.removeEventListener( Event.COMPLETE, onPaletteLoaded );
			palette.removeEventListener( ProgressEvent.PROGRESS, onPaletteProgress );
			palette.removeEventListener( PaletteErrorEvent.ERROR, onPaletteError );
		}
		
		private function onPaletteLoaded( e : Event ) : void
		{
			unsetPaletteListeners();
			next();
			
			e.stopImmediatePropagation();
		}
		
		private function onPaletteProgress( e : ProgressEvent ) : void
		{
			dialog.progress.setProgress( e.bytesLoaded, e.bytesTotal );
			dialog.progress.label = Math.round( ( e.bytesLoaded / e.bytesTotal ) * 100 ).toString() + '%';
			
			e.stopImmediatePropagation();
		}
		
		/**
		 * Список семплов которые не загрузились из-за ошибки 
		 */		
		private var errorSamples : Array;
		
		private function onPaletteError( e : PaletteErrorEvent ) : void
		{
			if ( ! errorSamples )
			{
				errorSamples = new Array();
			}
			
			errorSamples.push( e.sample.description );
	
			e.stopImmediatePropagation();
		}
		
		private function downloadPalette() : void
		{
			_status = DOWNLOADING_PALETTE;
			
			var pSamples  : Array = getProjectSampleIDs( projectData );
			var sample : BaseDescription;
			
			for each( sample in samplesInfo )
			{
				if ( pSamples.indexOf( sample.id ) == -1 )
				{
					palette.simpleAdd( sample );
				}
				else
				{
					palette.add( sample );
				}
			}
			
			if ( pSamples.length == 0 )
			{
				next();
			}
			else
			{
				palette.addEventListener( Event.COMPLETE, onPaletteLoaded, false, 1000 );
				palette.addEventListener( ProgressEvent.PROGRESS, onPaletteProgress, false, 1000 );
				palette.addEventListener( PaletteErrorEvent.ERROR, onPaletteError, false, 1000 );
			}
		}
		
		private function deserializeProject( xml : XML ) : void
		{
			if ( _status == SimpleTask.ERROR )
			{
				return;
			}
			
			_status = DESERIALIZING;
			
			try
			{
				if ( xml.name() != 'project' )
					throw new Error( "Can't found main tag project." );
				
				//Отключить отслеживание изменений
				vs.ignoreChanges = true;
				vs.dispatchEvent( new Event( ProjectEvent.START_UPDATE ) );
				
				if ( xml.bpm != undefined )
				{
					vs.bpm = Serialize.toFloat( xml.bpm );
				}
				
				if ( xml.position != undefined )
				{	
					vs.position = Serialize.toFloat( xml.position );
				}
				
				if ( xml.duration != undefined )
				{
					vs.duration = Serialize.toFloat( xml.duration );
				}
				
				if ( xml.scale != undefined )
				{
					vs.scale = Serialize.toFloat( xml.scale );
				}
				
				if ( xml.TrackControlGroup_currentState != undefined )
				{
					vs.controls.currentState = xml.TrackControlGroup_currentState;
				}
				
				if ( xml.viewType != undefined )
				{
					vs.viewType = Serialize.toInt( xml.viewType.text() );
				}
				
				if ( xml.loop != undefined )
				{	
					if ( ( xml.loop.start != undefined ) && ( xml.loop.end != undefined ) )
					{
						vs.startPosition = Serialize.toFloat( xml.loop.start );
						vs.endPosition   = Serialize.toFloat( xml.loop.end );
					}
					
					if ( xml.loop.@enabled != undefined )
					{
						vs.loop = Serialize.toBoolean( xml.loop.@enabled.toString() );
					}
				}
				
				var numTracks          : int = 0;
				var sampleDescriptions : Vector.<SampleClipboardRecord> = new Vector.<SampleClipboardRecord>();
				
				if ( xml.channels != undefined )
				{
					var soloChannel : int = -1;
					
					if ( xml.channels.solo != undefined )
					{
						soloChannel = Serialize.toInt( xml.channels.solo ); 	
					}	
					
					for each( var channel : XML in xml.channels.elements( 'channel' ) )
					{
						if ( channel.notes != undefined )
						{   
							for each( var note : XML in channel.notes.elements( 'note' ) )
							{
								var record : SampleClipboardRecord = SampleClipboardRecord.deserializeFromXML( note, palette );
								
								if ( record ) //Если в палитре нет такого семпла, то просто его игнорируем
								{
									var sample : PaletteSample = palette.getSample( record.sample_id );  
									
									if ( sample ) //Если в палитре нет такого семпла, то просто его игнорируем
									{
										record.description = sample.description;
										sampleDescriptions.push( record );   
										record.trackNumber = numTracks;	
									}
								}
							}
						}
						
						var volume : Number = ( channel.volume != undefined ) ? Serialize.toFloat( channel.volume ) : 1.0;
						var pan    : Number = ( channel.pan != undefined ) ? Serialize.toFloat( channel.pan ) : 0.0;
						var mono   : Boolean = ( channel.mono != undefined ) ? Serialize.toBoolean( channel.mono ) : false;
						
						vs.createTrack();
						seq.mixer.setVolumeAt( numTracks, volume );
						seq.mixer.setPanAt( numTracks, pan );
						seq.mixer.setMonoAt( numTracks, mono );
						
						numTracks ++;
					}
					
					vs.seq.mixer.soloChannel = soloChannel;	
				}
				
				vs.validateProperties();
				
				if ( xml.selectedTrack != undefined )
				{
					vs.selectedTrack = Serialize.toInt( xml.selectedTrack );
				}
				
				if ( xml.hpos != undefined )
				{
					vs.timeline.horizontalScrollPosition = Serialize.toFloat( xml.hpos );
				}
				
				if ( xml.vpos != undefined )
				{	
					vs.timeline.verticalScrollPosition = Serialize.toFloat( xml.vpos );
				}
				
				if ( numTracks > 0 )
				{
					vs.timeline.addSamplesByDescriptions( sampleDescriptions );
				}
				
				vs.validateNow();
				
				//Открыта/Закрыта библиотека семплов
				if ( xml.library != undefined )
				{
					if ( Serialize.toBoolean( xml.library.@visible ) )
					{
						ApplicationModel.library.show( Serialize.toInt( xml.library.text() ) );
					}
					else
					{
						ApplicationModel.library.hide();
					}
				}
				
				vs.durationMarker = api.userInfo.pro;
				
				vs.dispatchEvent( new ChangeBPMEvent( ChangeBPMEvent.BPM_CHANGED, vs.bpm, vs.bpm ) );
				vs.dispatchEvent( new SequencerEvent( SequencerEvent.PROJECT_CHANGED ) );
			}	
			catch( error : Error )
			{	
				//dispatchEvent( new ErrorEvent( ErrorEvent.ERROR, false, false, error.message, error.errorID ) );
				_status = SimpleTask.ERROR;
			}
			finally
			{
				//Включить отслеживание изменений
				vs.ignoreChanges = false;
				vs.dispatchEvent( new Event( ProjectEvent.END_UPDATE ) );
				next();
			}
		}
			
		/**
		 * Запускает процесс открытия 
		 * 
		 */		
		public function show() : void
		{
			showDialog();
			
			//Запускаем загрузку банера, если пользователь зашел не первый раз и у него не PRO аккаунт
			/*if ( api.userInfo.pro == false && api.firstTime == false )
			{
				loadAdsAPI();
			}*/
			
			next();
		}
		
		private function cancel() : void
		{
			if ( _status == DOWNLOADING_PALETTE )
			{
				unsetPaletteListeners();
			}
			
			if ( libAPI )
			{
				unsetLibApi();
			}
			
			vs.clearAll();
			vs.ignoreChanges = false;
			_status = SimpleTask.DONE;
			super.next();
		}
		
		private function showDialog() : void
		{
			if ( ! dialog )
			{
				dialog = new OpenProjectDialog();
				dialog.addEventListener( CloseEvent.CLOSE, onCloseDialog );
				PopUpManager.addPopUp( dialog, DisplayObject( FlexGlobals.topLevelApplication ), true );
				PopUpManager.centerPopUp( dialog );
				
				dialog.caption.text = 'Открываю ' + info.name;
			}
		}
		
		private function onCloseDialog( e : CloseEvent ) : void
		{
			cancel();
			closeDialog( Alert.CANCEL );
		}
		
		private function closeDialog( detail : uint ) : void
		{
			/*if ( detail == Alert.OK )
			{
				if ( adsLoader ) //Если банерная реклама запущена
				{
					if ( startTime == -1 ) //Если банерная реклама, не успела загрузиться
					{
						cancelLoadingAds();
					}
					else if ( timeElapsed < MIN_SHOW_ADS ) //проверяем прошло ли MIN_SHOW_ADS мс для отображения рекламы
					{
						setTimeout( closeDialog, MIN_SHOW_ADS - timeElapsed, detail );
						return;
					}
					
					hideAds();
				}
			}*/
			
			destroy();
			
			if ( dialog )
			{
				dialog.removeEventListener( CloseEvent.CLOSE, onCloseDialog );
				PopUpManager.removePopUp( dialog );
				dialog = null;
				
				dispatchEvent( new CloseEvent( CloseEvent.CLOSE, false, false, detail ) );
				System.gc();
			}
		}
		/*
		private static var adsLoader : Loader;
		
		private function loadAdsAPI() : void
		{
			if ( ! adsLoader )
			{
				adsLoader = new Loader();
				
				var context: LoaderContext = new LoaderContext(false, ApplicationDomain.currentDomain);
				context.securityDomain = SecurityDomain.currentDomain;
				
				adsLoader.contentLoaderInfo.addEventListener( Event.COMPLETE, onAdsAPILoaded );
				adsLoader.contentLoaderInfo.addEventListener( IOErrorEvent.IO_ERROR, onAdsAPIError );
				adsLoader.contentLoaderInfo.addEventListener( IOErrorEvent.NETWORK_ERROR, onAdsAPIError );
				adsLoader.contentLoaderInfo.addEventListener( SecurityErrorEvent.SECURITY_ERROR, onAdsAPIError );
				
				try
				{
				  adsLoader.load(new URLRequest('http://api.vk.com/swf/vk_ads.swf'), context);	
				}
				catch( e : Error )
				{
					onAdsAPIError( null );
				}
			}
			else
			{
				showAds();
			}
		}
		
		private function removeAdsLoaderListeners() : void
		{
			adsLoader.contentLoaderInfo.removeEventListener( Event.COMPLETE, onAdsAPILoaded );
			adsLoader.contentLoaderInfo.removeEventListener( IOErrorEvent.IO_ERROR, onAdsAPIError );
			adsLoader.contentLoaderInfo.removeEventListener( IOErrorEvent.NETWORK_ERROR, onAdsAPIError );
			adsLoader.contentLoaderInfo.removeEventListener( SecurityErrorEvent.SECURITY_ERROR, onAdsAPIError );
		}
		
		private function onAdsAPILoaded( e : Event ) : void
		{
			removeAdsLoaderListeners();
			showAds();
		}
		
		private function onAdsAPIError( e : Event ) : void
		{
			removeAdsLoaderListeners();
		}
		*/
		/**
		 * Ссылка на банер рекламы 
		 */		
		//private var baner : MainVKBanner;
		
		/**
		 * Отображает блок рекламы 
		 * 
		 */	
		/*
		private function showAds() : void
		{
			baner = new MainVKBanner( '3181' );
			 
			FlexGlobals.topLevelApplication.stage.addChild( baner );
			
			var params : BannersPanelVO = new BannersPanelVO();
			    params.ads_count = 3;
					
			baner.addEventListener( MainVKBannerEvent.LOAD_COMPLETE, onAdsLoaded );
			baner.addEventListener( MainVKBannerEvent.LOAD_IS_EMPTY, onAdsError );
			baner.addEventListener( MainVKBannerEvent.LOAD_ERROR, onAdsError );
					
			baner.initBanner( VKApi.params, params );	
		}
		
		private function removeBanerListeners() : void
		{
			baner.removeEventListener( MainVKBannerEvent.LOAD_COMPLETE, onAdsLoaded );
			baner.removeEventListener( MainVKBannerEvent.LOAD_IS_EMPTY, onAdsError );
			baner.removeEventListener( MainVKBannerEvent.LOAD_ERROR, onAdsError );
		}
		
		private function onAdsLoaded( e : Event ) : void
		{
			removeBanerListeners();
			startTime = getTimer();
		}
		
		private function onAdsError( e : Event ) : void
		{
			removeBanerListeners();
			hideAds();
		}
		*/
		/**
		 * закрывает блок рекламы 
		 * 
		 */	
		/*
		private function hideAds() : void
		{
			if ( baner )
			{
				FlexGlobals.topLevelApplication.stage.removeChild( baner );
				baner = null;	
			}
		}
		*/
		/**
		 * Отменяет загрузку рекламы 
		 * 
		 */	
		/*
		private function cancelLoadingAds() : void
		{
			if ( baner ) //Банер ещё не загрузился
			{
				if ( startTime == -1 )
				{
					removeBanerListeners();
				}
			}
			else
			{
				removeAdsLoaderListeners();
				adsLoader.close();
			}
		}
		*/
	}
}