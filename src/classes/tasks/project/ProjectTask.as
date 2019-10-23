package classes.tasks.project
{
	import com.adobe.crypto.AgeCrypt;
	import com.audioengine.sequencer.events.SequencerEvent;
	import com.thread.SimpleTask;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.external.ExternalInterface;
	import flash.utils.clearInterval;
	import flash.utils.setInterval;
	
	import mx.controls.Alert;
	import mx.core.FlexGlobals;
	import mx.events.CloseEvent;
	
	import classes.api.MainAPI;
	import classes.api.MainAPIImplementation;
	import classes.api.data.ProjectAccess;
	import classes.api.data.ProjectInfo;
	import classes.api.errors.APIError;
	import classes.api.events.LimitationsEvent;
	import classes.api.events.ProjectNameEvent;
	import classes.api.events.SaveProjectEvent;
	import classes.api.events.ServerUpdateEvent;
	import classes.api.social.vk.VKApi;
	import classes.tasks.project.views.EditProjectSettingsDialog;
	
	import components.controls.SaveLabel;
	import components.controls.tips.AddProToolTip;
	import components.managers.HintManager;
	import components.managers.PopUpManager;
	import components.sequencer.VisualSequencer;
	
	public class ProjectTask extends SimpleTask
	{
		/**
		 * Идет процесс проверки ограничений на максимальное количество миксов 
		 */		
		private static const CHECKING_LIMITATIONS : int = 5;
		
		/**
		 * Идет процесс сохранения 
		 */		
		private static const SAVING : int = 10;
		
		/**
		 * Идет процесс получения дефолтного имени 
		 */		
		private static const GETTING_DEFAULT_NAME : int = 20;
		
		/**
		 * Идет процесс переименования 
		 */		
		private static const CHANGING_INFO : int = 30;
		
		/**
		 * Идет процесс открытия проекта 
		 */		
		private static const OPENNING : int = 40;
		
		/**
		 * Идет процесс получения списка проектов 
		 */		
		private static const BROWSING : int = 50;
		
		/**
		 * Идет процесс удаления проекта 
		 */		
		private static const DELETE : int = 60;
		
		/**
		 * Очистка проекта 
		 */		
		private static const CLEAR : int = 70;
		
		/**
		 * Создать новый проект 
		 */		
		private static const TASK_NEW_MIX : int = 10;
		
		/**
		 * Создает новый проект не сохраняя предыдущий 
		 */		
		private static const TASK_NEW_MIX_WITHOUT_SAVE : int = 15;
		
		/**
		 * Переименовать проект
		 */		
		private static const TASK_CHANGING_PROJECT_INFO : int = 20;
		/**
		 * Сохранить проект 
		 */		
		private static const TASK_SAVE_PROJECT : int = 30;
		
		/**
		 * Перейти на другой проект 
		 */		
		private static const TASK_CHANGE_PROJECT : int = 40;
		
		/**
		 *Очистка проекта 
		 */		
		private static const CLEAR_PROJECT : int = 50;
		
		/**
		 * Текущая задача которую нужно выполнить 
		 */		
		private var currentTask : int = SimpleTask.NONE;
		
		/**
		 * Интервал автоматического сохранения 
		 */		
		private static const SAVE_INTERVAL : Number = 10000; //10c
		
		/**
		 * Идентификатор таймера 
		 */		
		private var timerID : int = -1;
        private var _needToSave : Boolean;
		
		private var vs         : VisualSequencer;
		private var saveLabel  : SaveLabel;
		private var api        : MainAPIImplementation;
		
		/**
		 * Параметры текущего проекта 
		 */		
		public var info : ProjectInfo;
		
		/**
		 * Если true, то это значит что проект открыт, но его нельзя сохранить 
		 */		
		public var projectsExceeded : Boolean = false;
		public var projectsErrorCode : int = APIError.OK;
		
		//Определяет открыт ли проект в режиме PRO
		private var _openedInProMode : Boolean;
		
		public function ProjectTask( vs : VisualSequencer, saveLabel : SaveLabel )
		{
			super();
			
			api = MainAPI.impl;
			api.addListener( ServerUpdateEvent.START_UPDATE, onStartUpdate );
			
			this.vs = vs;
			this.saveLabel = saveLabel;
			
			saveLabel.addEventListener( 'saveButtonClick', onSaveButtonClick );
			saveLabel.addEventListener( 'nameClick', onProjectSettingsClick );
			
			vs.addEventListener( SequencerEvent.SAMPLE_CHANGE, onSampleChange );
			vs.addEventListener( SequencerEvent.MIXER_PARAM_CHANGED, onSampleChange );
			vs.addEventListener( SequencerEvent.REMOVE_SAMPLE, onSampleChange );
			vs.addEventListener( SequencerEvent.ADD_SAMPLE, onSampleChange );
			vs.addEventListener( SequencerEvent.LOOP_CHANGED, onSampleChange );
			vs.addEventListener( SequencerEvent.DURATION_CHANGED, onSampleChange );
			vs.addEventListener( SequencerEvent.PALETTE_COMPACTED, onSampleChange );
			
			//Ф-ия обратного вызова для проверки сохранен ли микс при попытке закрыть окно браузера
			ExternalInterface.addCallback( 'getMixName', isMixSavedCallback ); 
		}
		
		private function isMixSavedCallback() : String
		{
			if ( _needToSave )
			{
				saveMix();
			}
			
			return _needToSave ? info.name : null;
		}
		
		//Проверяет открыт ли проект в режиме PRO
		public function get openedInProMode() : Boolean
		{
			return _openedInProMode;
		}
		
		//Определяет работаем мы сейчас с каким-либо проектом или нет
		public function get opened() : Boolean
		{
			return info != null;
		}
		
		private function onStartUpdate( e : ServerUpdateEvent ) : void
		{
			if ( _needToSave )
			{
				saveMix();
			}
		}
		
		public function get needToSave() : Boolean
		{
			return _needToSave;
		}
		
		public function destroy() : void
		{
			saveLabel.removeEventListener( 'saveButtonClick', onSaveButtonClick );
			saveLabel.removeEventListener( 'nameClick', onProjectSettingsClick );
			
			vs.removeEventListener( SequencerEvent.SAMPLE_CHANGE, onSampleChange );
			vs.removeEventListener( SequencerEvent.MIXER_PARAM_CHANGED, onSampleChange );
			vs.removeEventListener( SequencerEvent.REMOVE_SAMPLE, onSampleChange );
			vs.removeEventListener( SequencerEvent.ADD_SAMPLE, onSampleChange );
			vs.removeEventListener( SequencerEvent.LOOP_CHANGED, onSampleChange );
			vs.removeEventListener( SequencerEvent.PALETTE_COMPACTED, onSampleChange );
			
			api.removeAllObjectListeners( this );
		}
		
		public function get isNewProject() : Boolean
		{
			return info ? info.id == -1 : true;
		}
		
		private function onProjectSettingsClick( e : Event ) : void
		{
			if ( isCanToSave )
			{	
				showProjectSettingsDialog();
			}
			else
			{
				if ( info.readonly )
				{
					HintManager.show( 'Микс открыт только для просмотра т.к. автор запретил редактирование.', true, saveLabel.label );
				}
				else
				if ( projectsExceeded )
				{
					AddProToolTip.showLimitationTip( projectsErrorCode, saveLabel.label );
				} 
			}
		}	
		
		private var dialog : EditProjectSettingsDialog; 
		
		private function showProjectSettingsDialog() : void
		{
			if ( ! dialog )
			{
				//api.addListener( ProModeChangedEvent.PRO_EXPIRED, onProExpired, this, 1000 );
				
				stopTimer();
				syncInfo();
				
				dialog = new EditProjectSettingsDialog();
				dialog.defaultGenre = vs.seq.getMeanGenre();
				dialog.info = info.clone();
				dialog.addEventListener( CloseEvent.CLOSE, onCloseDialog );
				
				PopUpManager.addPopUp( dialog, DisplayObject( FlexGlobals.topLevelApplication ), true );
				PopUpManager.centerPopUp( dialog );
			}
		}
		
		private function onCloseDialog( e : CloseEvent ) : void
		{
			if ( e.detail == Alert.CANCEL )
			{
				hideProjectSettingsDialog();
				startTimer();
			}
			else 
			if ( e.detail == Alert.OK )
			{
				dialog.applying = true;
				updateMixInfo();
			}
		}
		
		private function hideProjectSettingsDialog() : void
		{
			if ( dialog )
			{
				HintManager.hideAll();
				dialog.removeEventListener( CloseEvent.CLOSE, onCloseDialog );
				PopUpManager.removePopUp( dialog );
				dialog = null;
			}
		}
		
		private var oldInfo : ProjectInfo;
		
		private function updateMixInfo() : void
		{
			oldInfo = info;
			info = dialog.info;
			currentTask = TASK_CHANGING_PROJECT_INFO;
			next();
		}
	
		private function serializeProject() : String
		{	
			var str : String = '<?xml version="1.0" encoding="UTF-8"?>';
			str += '<project>';
			
			str += '<bpm>' + vs.bpm + '</bpm>';
			str += '<position>' + vs.position + '</position>';
			str += '<duration>' + vs.duration + '</duration>';
			str += '<scale>' + vs.scale + '</scale>';
			str += '<hpos>' + vs.timeline.horizontalScrollPosition + '</hpos>';
			str += '<vpos>' + vs.timeline.verticalScrollPosition + '</vpos>';
			str += '<viewType>' + vs.viewType + '</viewType>';
			
			if ( vs.selectedTrack != -1 )
			{
				str += '<selectedTrack>' + vs.selectedTrack + '</selectedTrack>';
			}	
			
			str += '<TrackControlGroup_currentState>' + vs.controls.currentState + '</TrackControlGroup_currentState>';
			//Открыта/Закрыта библиотека семплов
			str += '<library visible="' + ApplicationModel.library.visible.toString() + '">' + ApplicationModel.library.viewStack.selectedIndex.toString() + '</library>';
			
			str += '<loop ';
            str += 'enabled="' + vs.loop.toString() + '">';
			str += '<start>' + vs.startPosition.toString() + '</start>';
			str += '<end>' + vs.endPosition.toString() + '</end>';
			str += '</loop>';
				
			
			//Палитра
			str += vs.seq.palette.serializeToXML();
			
			str += '<channels>';
			
			if ( vs.seq.mixer.soloChannel != -1 )
			{
				str += '<solo>' + vs.seq.mixer.soloChannel.toString() + '</solo>';
			}	
			
			var i : int = 0;
			
			while( i < vs.seq.numChannels )
			{	
				str += '<channel>';	
				str += '<volume>' + vs.seq.mixer.getVolumeAt( i ).toString() + '</volume>';
				str += '<pan>' + vs.seq.mixer.getPanAt( i ).toString() + '</pan>';
				
				if ( vs.seq.mixer.getMonoAt( i ) )
				{	
					str += '<mono>true</mono>';
				}
				
				str += vs.seq.getChannelAt( i ).listNote.serializeToXML();
				str += '</channel>';
				
				i ++;
			}
			
			str += '</channels>';
			
			str += '</project>';
			
			return str; 
		}
		
		private function checkError( errorCode : int ) : void
		{
			if ( dialog )
			{
				if ( errorCode == APIError.OK )
				{
					saveLabel.text = info.name;
					hideProjectSettingsDialog();	
				}
				else
				{
					dialog.applying = false;
					info = oldInfo;
					
					if ( errorCode == APIError.PROJECT_WITH_THIS_NAME_ALREADY_EXISTS )
					{
						dialog.setError( 'У тебя уже есть микс с таким именем. Придумай другое имя.' );
					}
					else
					{
						HintManager.show( 'Ошибка сохранения микса...', true, dialog.icon );
					}
				}
			}
			else if ( errorCode != APIError.OK )
			{
				if ( errorCode == APIError.PROJECT_WITH_THIS_NAME_ALREADY_EXISTS )
				{
				 HintManager.show( 'Не удается сохранить микс т.к. у тебя уже есть микс с таким именем. \n\n Щелкни здесь и придумай другое имя!', true, saveLabel, true );  	
				}
				else
				{
					HintManager.show( 'Ошибка сохранения микса...', true, saveLabel );
				}	
			}
			
			
			oldInfo = null;
		}
		
		private function onSaved( e : SaveProjectEvent ) : void
		{
			checkError( e.errorCode );
			api.removeListener( SaveProjectEvent.SAVE, onSaved );
			
			if ( ! e.error )
			{
				info.id = e.id;
				info.owner = api.userInfo.id; //Меняем владельца файла
			}
			
			next();
		}
		
		private function onUpdated( e : SaveProjectEvent ) : void
		{
			checkError( e.errorCode );
			api.removeListener( SaveProjectEvent.UPDATE, onUpdated );
			next();
		}
		
		private function syncInfo() : void
		{
			info.tempo = vs.bpm;
			info.duration = vs.realDuration;
			
			if ( ! info.userGenre )
			{
				info.genre = vs.seq.getMeanGenre();
			} 
		}
		
		private function save() : void
		{
			_status = SAVING;
			
			if ( currentTask == TASK_SAVE_PROJECT )
			{
				syncInfo();
			}	
			
			if ( ( info.id == -1 ) || ( ( info.owner != -1 ) && ( info.owner != api.userInfo.id ) ) ) //Если проект ещё ни разу не сохранялся или открыт чужой проект
			{
				api.addListener( SaveProjectEvent.SAVE, onSaved, this );
				api.saveProject( info, serializeProject() );
			}
			else
			{
				api.addListener( SaveProjectEvent.UPDATE, onUpdated, this );
				api.updateProject( info, serializeProject() );
			}
		}
		
		private function onGetDefaultProjectName( e : ProjectNameEvent ) : void
		{
			api.removeListener( ProjectNameEvent.DEFAULT_PROJECT_NAME, onGetDefaultProjectName );
			
			if ( e.error )
			{
				Alert.showError( LimitationsEvent.getErrorDescription( e.errorCode, true ) );
				_status = SimpleTask.ERROR;
			}
			else
			{
				info = getDefaultProjectInfo( e.name );	
			}
			
			next();
		}
		
		private function getDefaultName() : void
		{
			_status = GETTING_DEFAULT_NAME;
			
			projectsExceeded  = false;
			projectsErrorCode = APIError.OK;
			
			api.addListener( ProjectNameEvent.DEFAULT_PROJECT_NAME, onGetDefaultProjectName, this );
			api.getDefaultProjectName();
		}
		
		private function onGotLimitations( e : LimitationsEvent ) : void
		{
			api.removeListener( LimitationsEvent.GOT_LIMITATIONS, onGotLimitations );
			
			projectsExceeded  = e.projectsExceeded;
			projectsErrorCode = e.projectsErrorCode;
			
			next();
		}
		
		private function getProjectsLimitations() : void
		{
			_status = CHECKING_LIMITATIONS;
			
			api.addListener( LimitationsEvent.GOT_LIMITATIONS, onGotLimitations );
			api.getLimitations();
		}
		
		private function getDefaultProjectInfo( name : String ) : ProjectInfo
		{
			var d : ProjectInfo = new ProjectInfo();
			    d.name = name;
				d.genre = 'na';
				d.userGenre = false;
				d.description = '';
				d.access = ProjectAccess.ALL;
				d.readonly = false;
			
			return d;
		}
		
		override protected function operationComplete():void
		{
			currentTask = SimpleTask.NONE;
			_status = SimpleTask.NONE;
			super.operationComplete();
		}
		
		override protected function next():void
		{
			if ( _status == SimpleTask.ERROR )
			{
				super.next();
				currentTask = SimpleTask.NONE;
				return;
			}
			
			switch( currentTask )
			{
				case TASK_NEW_MIX : 
					switch( _status )
					{
						case SimpleTask.NONE :
							if ( _needToSave )
							{
								stopTimer();
								save();
							}
							else
							{
								getDefaultName();
							}
							
							saveLabel.currentState = 'saving';
							PopUpManager.showLoading();
							operationStart();
							break;
						
						case SAVING :
							getDefaultName();
							_needToSave = false;
							break;
						
						case GETTING_DEFAULT_NAME :
							vs.clearAll();
							
							//Маркер длительности отображать только для пользователей режима PRO
							vs.durationMarker = api.userInfo.pro;
							
							saveLabel.text = info.name;
							saveLabel.currentState = 'saved';
							
							_openedInProMode = api.userInfo.pro;
							
							PopUpManager.hideLoading();
							operationComplete();
							break;
					}
					break;
				
				case TASK_NEW_MIX_WITHOUT_SAVE : 
					switch( _status )
					{
						case SimpleTask.NONE :
							    _needToSave = false;
								stopTimer();
								getDefaultName();
							
							
							saveLabel.currentState = 'saving';
							PopUpManager.showLoading();
							operationStart();
							break;
						
						case GETTING_DEFAULT_NAME :
							vs.clearAll();
							
							saveLabel.text = info.name;
							saveLabel.currentState = 'saved';
							
							_openedInProMode = api.userInfo.pro;
							
							PopUpManager.hideLoading();
							operationComplete();
							break;
					}
					break;
				
				case TASK_SAVE_PROJECT :
					switch( _status )
					{
						case SimpleTask.NONE :
							stopTimer();
							save();
							saveLabel.currentState = 'saving';
							operationStart();
							break;
						case SAVING :
							
							//Изменяем url
							changeWindowLocation( info.id ); 
							
							saveLabel.currentState = 'saved';
							_needToSave = false;
							operationComplete();
							break;
					}
					
					break;
				
				case TASK_CHANGING_PROJECT_INFO :
					switch( _status )
					{
						case SimpleTask.NONE :
							save();
							saveLabel.currentState = 'saving';
							operationStart();
							break;
						
						case SAVING :
							saveLabel.currentState = 'saved';
							PopUpManager.hideLoading();
							operationComplete();
							break;	
					}
					
					break;
				
				case TASK_CHANGE_PROJECT : 
					switch( _status )
					{
						case SimpleTask.NONE :
							operationStart();
							stopTimer();
							
							if ( _needToSave )
							{
								saveLabel.currentState = 'saving';
								save();
								break;
							}
							else _status = SAVING;
							
						
						case SAVING : getProjectsLimitations();
							          break;
							
						case CHECKING_LIMITATIONS :
							_needToSave = false;
							info = newInfo;
							saveLabel.currentState = 'saved';
							saveLabel.text = info.name;
							_openedInProMode = api.userInfo.pro;
							
							//Изменяем url
							changeWindowLocation( info.id );
							
							operationComplete();
							break;
					}
					
				case CLEAR_PROJECT :
				{
					switch( _status )
					{
						case CLEAR :
							//Очищаем параметры url
							changeWindowLocation();
							stopTimer();
							_needToSave = false;
							info = null;
							saveLabel.text = '';
							saveLabel.currentState = 'saved';
							operationComplete();
							break;	
					}
				}
					
			}
			
			super.next();
		}
		
		/**
		 * Создает новый микс
		 */		
		public function createNewMix() : void
		{
			currentTask = TASK_NEW_MIX;
			next();
		}
		/*
		public function createNewMixWithoutSaving() : void
		{
			currentTask = TASK_NEW_MIX_WITHOUT_SAVE;
			next();
		}
		*/
		public function saveMix() : void
		{
			currentTask = TASK_SAVE_PROJECT;
			next();
		}
		
		private var newInfo : ProjectInfo;
		
		public function changeProject( info : ProjectInfo ) : void
		{
			newInfo = info.clone();
			
			delete newInfo[ 'updated' ];
			delete newInfo[ 'created' ];
			
			currentTask = TASK_CHANGE_PROJECT;
			next();
		}
		
		private function onSaveButtonClick( e : Event ) : void
		{
			saveMix();
		}
		
		/**
		 * Определяет можно ли сохранить текущий микс 
		 * @return 
		 * 
		 */		
		public function get isCanToSave() : Boolean
		{
			if ( ! info )
			{
				return true;
			}
			
			if ( info.owner == api.userInfo.id )
			{
				return true;
			}
			else if ( projectsExceeded )
			{
				return false;
			}
			else if ( info.readonly )
			{
				return false;
			}
			
			return true;
		}
		
		private function onSampleChange( e : SequencerEvent ) : void
		{
			stopTimer();
			
			if ( ! isCanToSave || ( _status != SimpleTask.NONE ) )
			{
				return;
			}
			
			//trace( vs.numSamples, vs.numVisualSamples );
			//Происходит процесс перетаскивания в результате которого несколько семплов находятся на виртуальной ( "ещё не созданной дорожке" )
			if ( ( vs.numTracks == 0 ) || ( vs.numSamples != vs.numVisualSamples ) )
			{
				return;
			}	
			
			_needToSave = true;
			
			startTimer();
			
			if ( saveLabel.currentState != 'needToSave' )
			{
				saveLabel.currentState = 'needToSave';
			}
		}
		
		public function startTimer() : void
		{
			if ( ! _needToSave ) return;
			
			if ( timerID == -1 )
			{
				timerID = setInterval( tick, SAVE_INTERVAL );
			}
		}
		
		public function stopTimer() : void
		{
			if ( timerID != -1 )
			{
				clearInterval( timerID );
				timerID = -1;
			}
		}
		
		private function tick() : void
		{
			saveMix();
		}
		
		public function clear() : void
		{
			currentTask = CLEAR_PROJECT;
			
			if ( _status == SimpleTask.NONE )
			{
				_status = CLEAR;
				next();
			}
			else
			{
				_status = CLEAR;
			}
		}
		
		private function changeWindowLocation( pi : int = -1000 ) : void
		{
			if ( VKApi.initialized )
			{
				var params : String = '';
				
				if ( pi != -1000 )
				{
					params = Settings.PROJECT_ID_PARAM_NAME + '=' + AgeCrypt.encode( pi.toString() );
				}
				
				VKApi.impl.callMethod( 'setLocation', params, false );
			}
		}
	}
}