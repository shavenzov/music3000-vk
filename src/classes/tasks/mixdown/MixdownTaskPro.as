package classes.tasks.mixdown
{
	import flash.display.DisplayObject;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.system.System;
	
	import mx.controls.ProgressBarMode;
	import mx.core.FlexGlobals;
	import mx.events.CloseEvent;
	
	import classes.Sequencer;
	import classes.SequencerImplementation;
	import classes.api.MainAPI;
	import classes.api.MainAPIImplementation;
	import classes.api.PublisherAPI;
	import classes.api.data.ProjectInfo;
	import classes.api.events.ProModeChangedEvent;
	import classes.api.social.vk.VKApi;
	import classes.tasks.mixdown.events.MixdownOptionsEvent;
	import classes.tasks.mixdown.views.MixdownDialog;
	import classes.tasks.mixdown.views.MixdownOptionsDialog;
	
	import components.managers.PopUpManager;
	
	import flashx.textLayout.conversion.TextConverter;
	
	public class MixdownTaskPro extends EventDispatcher
	{
		private var dialog : MixdownDialog;
		
		/**
		 * Информация о миксе 
		 */		
		private var info : ProjectInfo;
		
		/**
		 * Публикатор 
		 */		
		private var publisher   : MixdownPro;
		
		/**
		 * Параметры сценария публикации 
		 */		
		private var params : Object;
		
		/**
		 * Ссылка на скачивание 
		 */		
		private var download_url : String;
		
		/**
		 * Идентификатор альбома в котором был сохранен микс, в случае публикации микса в "Мои аудиозаписи" 
		 */		
		private var album_id : String;
		
		private var api : MainAPIImplementation;
		private var seq : SequencerImplementation;
		
		public function MixdownTaskPro( info : ProjectInfo ) : void
		{
			super();
			
			api = MainAPI.impl;
			seq = Sequencer.impl;
			
			this.info = info;
		}
		
		private function showSaveButton() : void
		{
			if ( api.userInfo.pro )
			{
				dialog.header.text = 'Опубликовано';
				dialog.saveButton.visible = dialog.saveButton.includeInLayout = true;
				dialog.saveButton.setStyle( 'icon', params.format == PublisherAPI.FORMAT_MP3 ? Assets.MP3_ICON : Assets.WAV_ICON );
				dialog.saveButton.addEventListener( MouseEvent.CLICK, onSaveButtonClick );
			}
		}
		
		private function onSaveButtonClick( e : MouseEvent ) : void
		{
            ApplicationModel.exitFromFullScreen();
			
			navigateToURL( new URLRequest( download_url ), '_blank' );
			exit();
		}
		
		private function exit() : void
		{
			destroy();
			hideMixdownDialog();
			dispatchEvent( new CloseEvent( CloseEvent.CLOSE ) );
		}
		
		private function destroy() : void
		{
			if ( publisher )
			{
				if ( publisher.hasEventListener( Event.CHANGE ) )
				{
					unsetThreadListeners();
				}
				
				publisher.clear();
				publisher = null;
			}
			
			System.gc();
		}
		
		private function onClickCancelButton( e : Event ) : void
		{
			exit();
		}
		
		private function setThreadListeners() : void
		{
			publisher.addEventListener( Event.COMPLETE, onMixDownComplete );
			publisher.addEventListener( ProgressEvent.PROGRESS, onMixDownProgress );
			publisher.addEventListener( ErrorEvent.ERROR, onMixDownError );
			
			publisher.addEventListener( Event.CHANGE, onStatusChange );
		}
		
		private function unsetThreadListeners() : void
		{
			publisher.removeEventListener( Event.COMPLETE, onMixDownComplete );
			publisher.removeEventListener( ProgressEvent.PROGRESS, onMixDownProgress );
			publisher.removeEventListener( ErrorEvent.ERROR, onMixDownError );
			
			publisher.removeEventListener( Event.CHANGE, onStatusChange );
		}
		
		private function onStatusChange( e : Event ) : void
		{
		  if ( publisher.status == MixdownPro.INITIALIZING ||
			   publisher.status == MixdownPro.PROCESSING   ||
			   publisher.status == MixdownPro.ENDING       ||
			   publisher.status == MixdownPro.PUBLISHING )	   
		  {
			  dialog.progress.indeterminate = true;
			  dialog.progress.mode = ProgressBarMode.EVENT;
			  
			  if ( publisher.status == MixdownPro.PROCESSING )
			  {
				  dialog.progress.label = 'Ещё несколько секунд...';
			  }
			  else if ( publisher.status == MixdownPro.PUBLISHING )
			  {
				  dialog.progress.label = 'Ещё совсем чуть-чуть...'; 
			  }
			  else
			  {
				  dialog.progress.label = 'Секундочку...'; 
			  }
		  }
		  else
		  {
			  dialog.progress.indeterminate = false;
			  dialog.progress.mode = ProgressBarMode.MANUAL;
		  }
			
		  updateStatus( publisher.statusString );
		}
		
		private function onMixDownComplete( e : Event ) : void
		{
			unsetThreadListeners();
			
			download_url = publisher.download_url;
			album_id = publisher.album_id;
			
			publisher = null;
			
			dialog.currentState = 'done';
			
			if ( params.action == MixdownAction.SAVE_TO_MY_AUDIO )
			{
				//dialog.doneText.textFlow = TextConverter.importToFlow( 'Микс ' + info.name + ' успешно опубликован в альбоме <a href="http://vk.com/audio?album_id=' + album_id + '" target="_blank">' + Settings.VK_ALBUM_NAME + '</a>', TextConverter.TEXT_FIELD_HTML_FORMAT );
				dialog.doneText.textFlow = TextConverter.importToFlow( 'Микс "' + info.name + '" успешно опубликован в разделе <a href="' + Settings.resolveProtocol( 'vk.com/audio' ) + '" target="_blank">Аудиозаписи</a>', TextConverter.TEXT_FIELD_HTML_FORMAT );
			}
			else
			{
				dialog.doneText.text = 'Микс ' + info.name + ' успешно опубликован!';
			}
			
			showSaveButton();
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
			dialog.currentState = 'error';
			dialog.status.setStyle( 'color', 0xff0000 );
			
			if ( e.errorID == 1000 )
			{
				updateStatus( 'Недостаточно памяти для выполнения операции. Пожалуйста, закройте лишние программы на компьютере и повторите публикацию.' );
			}
			else
			{
				updateStatus( 'Произошла ошибка ' + e.text + ' :( ' + publisher.statusString + '.' );
			}
			
			stopMixDown();
		}
		
		private function startMixdown() : void
		{
			var tags : Object = {
				
				
					artist : VKApi.userFullName,
					title : info.name,
					composer : VKApi.userFullName,
					TBPM : Sequencer.impl.bpm,
					date : new Date().fullYear,
						publisher : Settings.APPLICATION_NAME,
						encoder : 'Музыкальный Конструктор http://vk.com/musconstructor',
						encoded_by : 'Музыкальный Конструктор http://vk.com/musconstructor',
						TALB : "Мои миксы"         
				
			};
			
			publisher = new MixdownPro( info, seq, { format : params.format, quality : params.quality, tags : tags }, params.action == MixdownAction.SAVE_TO_MY_AUDIO, params.playingArea.from, params.playingArea.to );
			
			setThreadListeners();
			
			publisher.run();
			
			onStatusChange( null );
		}
		
		public function stopMixDown() : void
		{
			if ( publisher )
			{
				unsetThreadListeners();
				publisher.clear();
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
			startMixdown();
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