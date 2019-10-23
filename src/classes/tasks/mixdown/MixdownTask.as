package classes.tasks.mixdown
{
	import com.audioengine.format.tasks.Mixdown;
	import com.audioengine.format.tasks.Normalizer;
	import com.audioengine.format.tasks.ProcessingStack;
	import com.audioengine.format.tasks.ShineMp3Encoder;
	import com.audioengine.format.tasks.WaveEncoder;
	import com.thread.SimpleTask;
	import com.thread.Thread;
	
	import flash.display.DisplayObject;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.net.FileReference;
	import flash.system.System;
	
	import mx.controls.ProgressBarMode;
	import mx.core.FlexGlobals;
	import mx.events.CloseEvent;
	
	import classes.Sequencer;
	import classes.SequencerImplementation;
	import classes.api.MainAPI;
	import classes.api.MainAPIImplementation;
	import classes.api.data.ProjectInfo;
	import classes.api.events.ProModeChangedEvent;
	import classes.api.social.vk.VKApi;
	import classes.api.social.vk.tasks.PublishAudio;
	import classes.tasks.mixdown.events.MixdownOptionsEvent;
	import classes.tasks.mixdown.views.MixdownDialog;
	import classes.tasks.mixdown.views.MixdownOptionsDialog;
	
	import components.managers.PopUpManager;
	
	import flashx.textLayout.conversion.TextConverter;
	
	public class MixdownTask extends SimpleTask
	{
		private static const CODING : int = 10;
		private static const WAITING_FOR_SAVING : int = 15;
		private static const SAVING : int = 20;
		private static const PUBLISHING : int = 30;
		private static const WAITING_FOR_CLOSE : int = 40;
		
		private var dialog : MixdownDialog;
		
		/**
		 * Информация о миксе 
		 */		
		private var info : ProjectInfo;
		
		/**
		 * Стек обработки 
		 */		
		private var task   : ProcessingStack;
		private var thread : Thread;
		
		//Для сохранения на компьютере пользователя
		private var file : FileReference;
		
		private var publisher : PublishAudio;
		private var album_id : String;
		
		/**
		 * Параметры сценария публикации 
		 */		
		private var params : Object;
		
		private var api : MainAPIImplementation;
		private var seq : SequencerImplementation;
		
		public function MixdownTask( info : ProjectInfo ) : void
		{
			super();
			
			api = MainAPI.impl;
			seq = Sequencer.impl;
			
			this.info = info;
		}
		
		override protected function next():void
		{
			switch( _status )
			{
				case SimpleTask.NONE : 
					_status = CODING; 
					startMixdown();
					                   
				break;
				
				case CODING : if ( params.action == MixdownAction.SAVE_TO_MY_AUDIO )
				               {
					              _status = PUBLISHING;
					              dialog.progress.indeterminate = true;
					              dialog.progress.mode = ProgressBarMode.EVENT;
					              dialog.progress.label = 'Минуточку...';
					              publish();
				               }
				               else if ( params.action == MixdownAction.SAVE_TO_MY_COMPUTER )
							   {
								   _status = WAITING_FOR_SAVING;
								   dialog.currentState = 'done';
								   dialog.doneText.text = 'Микс ' + info.name + ' успешно опубликован!';
								   showSaveButton();
							   }
					
					           break;
				
				case WAITING_FOR_SAVING : _status = SAVING;
					                   dialog.currentState = 'mixdown';
					                   dialog.status.text = 'Сохранение...';
									   dialog.header.text = 'Сохранение';
									   break;
					          
				
				case PUBLISHING : _status = WAITING_FOR_SAVING;
					              dialog.currentState = 'done';
								  //dialog.doneText.textFlow = TextConverter.importToFlow( 'Микс ' + info.name + ' успешно опубликован в альбоме <a href="http://vk.com/audio?album_id=' + album_id + '" target="_blank">' + Settings.VK_ALBUM_NAME + '</a>', TextConverter.TEXT_FIELD_HTML_FORMAT );
								  dialog.doneText.textFlow = TextConverter.importToFlow( 'Микс "' + info.name + '" успешно опубликован в разделе <a href="' + Settings.resolveProtocol( 'vk.com/audio' ) + '" target="_blank">Аудиозаписи</a>', TextConverter.TEXT_FIELD_HTML_FORMAT );
								  showSaveButton();
								  
					              break;
				
				case SAVING : _status = SimpleTask.DONE;
										  exit();
								          break;
				
				case SimpleTask.ERROR : _status = WAITING_FOR_CLOSE;
					                    dialog.currentState = 'error';
					break;
			}
			
			super.next();
		}
		
		private function showSaveButton() : void
		{
			if ( api.userInfo.pro )
			{
				dialog.header.text = 'Опубликовано';
				dialog.saveButton.visible = dialog.saveButton.includeInLayout = true;
				dialog.saveButton.setStyle( 'icon', params.action == MixdownAction.SAVE_TO_MY_AUDIO ? Assets.MP3_ICON : Assets.WAV_ICON );
				dialog.saveButton.addEventListener( MouseEvent.CLICK, onSaveButtonClick );
			}
		}
		
		private function onSaveButtonClick( e : MouseEvent ) : void
		{
            ApplicationModel.exitFromFullScreen();
			saveFile();
		}
		
		private function exit() : void
		{
			destroy();
			hideMixdownDialog();
			dispatchEvent( new CloseEvent( CloseEvent.CLOSE ) );
		}
		
		private function destroy() : void
		{
			if ( task )
			{
				task.clear();
				task = null;
			}
			
			api.removeAllObjectListeners( this );
			
			System.gc();
		}
		
		private function onClickCancelButton( e : Event ) : void
		{
			if ( _status == CODING )
			{
				stopMixDown();	
			}
			else
		    if ( _status == PUBLISHING )
			{
				if ( publisher )
				{
					publisher.cancel();
					unsetListenersForPublisher();
					destroy();
				}	
			}
			else if ( _status == SAVING )
			{
				file.cancel();
				onLocalFileComplete( null );
			}
			
			exit();
		}
		
		private function setListenersForFileReference( file : FileReference ) : void
		{
			file.addEventListener( ProgressEvent.PROGRESS, onMixDownProgress );
			file.addEventListener( Event.COMPLETE, onLocalFileComplete );
			file.addEventListener( IOErrorEvent.IO_ERROR, onLocalFileIOError );
			file.addEventListener( Event.CANCEL, onLocalFileCancel );
			file.addEventListener( Event.SELECT, onFileSelected );
		}
		
		private function removeListenersForFileReference( file : FileReference ) : void
		{	
			file.removeEventListener( ProgressEvent.PROGRESS, onMixDownProgress );
			file.removeEventListener( Event.COMPLETE, onLocalFileComplete );
			file.removeEventListener( IOErrorEvent.IO_ERROR, onLocalFileIOError );
			file.removeEventListener( Event.CANCEL, onLocalFileCancel );
			file.removeEventListener( Event.SELECT, onFileSelected );
		}
		
		private function onFileSelected( e : Event ) : void
		{
			next();
		}
		
		private function onLocalFileCancel( e : Event ) : void
		{
			clearFileReference();
		}
		
		private function onLocalFileComplete( e : Event ) : void
		{
			clearFileReference();
			next();
		}
		
		private function onLocalFileIOError( e : IOErrorEvent ) : void
		{
			dialog.status.setStyle( 'color', 0xff0000 );
			dialog.status.text = e.text;
			clearFileReference();
		}
		
		private function clearFileReference() : void
		{
			removeListenersForFileReference( file );
			file = null;
		}
		
		private function saveFile() : void
		{
			file = new FileReference();
			setListenersForFileReference( file );
			
			file.save( task.outputData, info.name + ( params.action == MixdownAction.SAVE_TO_MY_AUDIO ? '.mp3' : '.wav' ) );
		}
		
		
		private function setListenersForPublisher() : void
		{
			publisher.addEventListener( Event.CHANGE, onPublisherStatusChange );
		}
		
		private function unsetListenersForPublisher() : void
		{
			publisher.removeEventListener( Event.CHANGE, onPublisherStatusChange );
			publisher = null;
		}
		
		private function onPublisherStatusChange( e : Event ) : void
		{
			if ( publisher.status == SimpleTask.ERROR )
			{
				dialog.status.setStyle( 'color', 0xff0000 );
				
				updateStatus( 'Произошла ошибка ' + publisher.statusString );
				unsetListenersForPublisher();
				_status = SimpleTask.ERROR;
				next();
				return;
			}
			if ( publisher.status == SimpleTask.DONE )
			{
				album_id = publisher.album_id;
				unsetListenersForPublisher();
				next();
				return;
			}
			
			updateStatus( publisher.statusString );
		}
		
		private function publish()  : void
		{
			publisher = new PublishAudio( task.outputData, info );
			setListenersForPublisher();
			publisher.run();
		}
		
		private function setThreadListeners() : void
		{
			thread.addEventListener( Event.COMPLETE, onMixDownComplete );
			thread.addEventListener( ProgressEvent.PROGRESS, onMixDownProgress );
			thread.addEventListener( ErrorEvent.ERROR, onMixDownError );
			
			task.addEventListener( Event.CHANGE, onStatusChange );
		}
		
		private function unsetThreadListeners() : void
		{
			thread.removeEventListener( Event.COMPLETE, onMixDownComplete );
			thread.removeEventListener( ProgressEvent.PROGRESS, onMixDownProgress );
			thread.removeEventListener( ErrorEvent.ERROR, onMixDownError );
			
			task.removeEventListener( Event.CHANGE, onStatusChange );
		}
		
		private function onStatusChange( e : Event ) : void
		{
		  updateStatus( task.statusString );
		}
		
		private function onMixDownComplete( e : Event ) : void
		{
			unsetThreadListeners();
			thread = null;
			next();
		}
		
		private function onMixDownProgress( e : ProgressEvent ) : void
		{
			updateProgress( e.bytesLoaded, e.bytesTotal );
		}
		
		private function updateProgress( progress : Number, total : Number ) : void
		{
			dialog.progress.setProgress( progress, total );
			dialog.progress.label = Math.round( ( progress / total ) * 100 ).toString() + '%';
		}
		
		private function updateStatus( text : String ) : void
		{
			dialog.status.text = text;
		}
		
		private function onMixDownError( e : ErrorEvent ) : void
		{
			dialog.status.setStyle( 'color', 0xff0000 );
			
			if ( e.errorID == 1000 )
			{
				updateStatus( 'Недостаточно памяти для выполнения операции. Пожалуйста, закройте лишние программы на компьютере и повторите публикацию.' );
			}
			else
			{
				updateStatus( 'Произошла ошибка ' + e.text + ' :( ' + task.statusString + '.' );
			}
			
			stopMixDown();
			_status = SimpleTask.ERROR;
			next();
		}
		
		private function startMixdown() : void
		{
				var normalizer  : Normalizer = new Normalizer();
				var mixdown     : Mixdown    = new Mixdown( seq, params.playingArea.from, params.playingArea.to );
				
				task = new ProcessingStack();
				
				task.add( mixdown );
				
				if ( params.action == MixdownAction.SAVE_TO_MY_AUDIO )
				{
					task.add( normalizer );
					task.add( new WaveEncoder( 16, normalizer ) );
					task.add( new ShineMp3Encoder( { 
						TPE1 : VKApi.userFullName,
						TIT2 : info.name, 
						TBPM : Sequencer.impl.bpm,
						TYER : new Date().fullYear,
						TSSE : Settings.APPLICATION_NAME,
						TALB : "Этот микс создан Web приложением Музыкальный Конструктор. http://vk.com/musconstructor"
					} ) );
				}
				else
				if ( params.action == MixdownAction.SAVE_TO_MY_COMPUTER )
				{
					task.add( normalizer );
					task.add( new WaveEncoder( params.bits, normalizer ) );
				}
				
				task.calcTotal( mixdown.total );
				
				thread = new Thread( task );
				setThreadListeners();
				thread.start();
				onStatusChange( null );
		}
		
		public function stopMixDown() : void
		{
			if ( thread )
			{
				unsetThreadListeners();
				thread.suspend();
				task.clear();
				thread.destroy();
				thread = null;
				task = null;
			}
		}
		
		private var mixdownOptions : MixdownOptionsDialog;
		
		private function showMixdownOptionsDialog() : void
		{
			if ( ! mixdownOptions )
			{
				mixdownOptions = new MixdownOptionsDialog();
				mixdownOptions.addEventListener( MixdownOptionsEvent.SELECTED, onMixdownOptionsSelected );
				mixdownOptions.addEventListener( CloseEvent.CLOSE, onMixdownOptionsDialogCanceled );
				
				PopUpManager.addPopUp( mixdownOptions, DisplayObject( FlexGlobals.topLevelApplication ), true );
				PopUpManager.centerPopUp( mixdownOptions );
			}
		}
		
		private function hideMixdownOptionsDialog() : void
		{
			if ( mixdownOptions )
			{
				PopUpManager.removePopUp( mixdownOptions );
				mixdownOptions.removeEventListener( MixdownOptionsEvent.SELECTED, onMixdownOptionsSelected );
				mixdownOptions.removeEventListener( CloseEvent.CLOSE, onMixdownOptionsDialogCanceled );
				mixdownOptions = null;
			}
		}
		
		private function onMixdownOptionsSelected( e : MixdownOptionsEvent ) : void
		{
			params = e.params;
			hideMixdownOptionsDialog();
			showMixdownDialog();
		    next();
		}
		
		private function onMixdownOptionsDialogCanceled( e : CloseEvent ) : void
		{
			hideMixdownOptionsDialog();
			exit();
		}
		
		private function showMixdownDialog() : void
		{
			if ( ! dialog )
			{
				dialog = new MixdownDialog();
				PopUpManager.addPopUp( dialog, DisplayObject( FlexGlobals.topLevelApplication ), true );
				PopUpManager.centerPopUp( dialog );
				
				dialog.header.text = 'Публикую ' + info.name;
				
				dialog.closeButton.addEventListener( MouseEvent.CLICK, onClickCancelButton );
			}
		}
		
		private function hideMixdownDialog() : void
		{
			if ( dialog )
			{
				dialog.closeButton.removeEventListener( MouseEvent.CLICK, onClickCancelButton );
				PopUpManager.removePopUp( dialog );
				dialog = null;
			}
		}
		
		private function onProExpired( e : ProModeChangedEvent ) : void
		{
			if ( mixdownOptions )
			{
				onMixdownOptionsDialogCanceled( null );
				return;
			}
			
			onClickCancelButton( null );
		}
		
		public function show() : void
		{
			//Если во время открытия микса истек срок действия PRO режима, отменяем любые операции
			api.addListener( ProModeChangedEvent.PRO_EXPIRED, onProExpired, this, 1000 );  
			
			/*if ( chooseOptions )
			{*/
				showMixdownOptionsDialog();
			/*}
			else
			{
				params = { action : MixdownAction.SAVE_TO_MY_AUDIO };
				showMixdownDialog();
				next();
			}*/
		}
		
		private function hide() : void
		{
			dispatchEvent( new CloseEvent( CloseEvent.CLOSE ) );
		}
			
	}
}