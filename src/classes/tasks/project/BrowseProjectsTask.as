package classes.tasks.project
{
	import classes.api.MainAPI;
	import classes.api.MainAPIImplementation;
	import classes.api.data.ProjectInfo;
	import classes.api.errors.APIError;
	import classes.api.events.BrowseProjectEvent;
	import classes.api.events.RemoveProjectEvent;
	import classes.api.events.SaveProjectEvent;
	import classes.api.social.vk.VKApi;
	import classes.tasks.project.views.BrowseProjectsDialog;
	import classes.tasks.project.views.EditProjectSettingsDialog;
	
	import com.thread.SimpleTask;
	
	import components.managers.HintManager;
	import components.managers.PopUpManager;
	
	import flash.display.DisplayObject;
	import flash.events.MouseEvent;
	
	import mx.controls.Alert;
	import mx.core.FlexGlobals;
	import mx.events.CloseEvent;
	import mx.utils.ObjectUtil;
	
	import spark.events.IndexChangeEvent;
	
	public class BrowseProjectsTask extends SimpleTask
	{
		/**
		 * Параметры пользователя, по умолчанию сохраняется между открытиями браузера 
		 */		
		private static var lastUser : Object;
		
		private static const BROWSING      : int = 10;
		private static const REMOVING      : int = 20;
		private static const UPDATING_INFO : int = 30;
		private static const UPDATE_INFO_ERROR : int = 40;
		
		/**
		 * Получить список всех проектов 
		 */		
		private static const TASK_BROWSE_PROJECTS : int = 10;
		/**
		 * Удалить проект 
		 */		
		private static const TASK_REMOVE_PROJECT : int = 20;
		/**
		 * Обновить информацию о проекте 
		 */		
		private static const TASK_UPDATE_INFO : int = 30;
		
		/**
		 * Текущая задача которую нужно выполнить 
		 */		
		private var currentTask : int = SimpleTask.NONE;
		
		private var api : MainAPIImplementation;
		
		/**
		 * Выбранный пользователем проект 
		 */		
		public var selectedProject : ProjectInfo;
		
		/**
		 * Информация о текущем проекте 
		 */		
		private var info : Object;
		
		/**
		 * Текущий выбранный пользователь чьи миксы необходимо отображать 
		 */		
		public var selectedUser : Object;
		
		public function BrowseProjectsTask( info : ProjectInfo, selectedUser : Object = null )
		{
			super();
			this.info = info;
			api = MainAPI.impl;
			
			if ( selectedUser )
			{
				this.selectedUser = selectedUser;
				lastUser = selectedUser;
			}
			else
			{
				if ( lastUser )
				{
					this.selectedUser = lastUser;
				}
				else
				{
					this.selectedUser = VKApi.userInfo;
					lastUser = VKApi.userInfo;
				}
			}
		}
		
		public function destroy() : void
		{
			api.removeAllObjectListeners( this );
		}
		
		private var browser : BrowseProjectsDialog;
		
		public function show() : void
		{
			if ( ! browser )
			{
				browser = new BrowseProjectsDialog();
				browser.addEventListener( CloseEvent.CLOSE, onCloseBrowser );
				
				PopUpManager.addPopUp( browser, DisplayObject( FlexGlobals.topLevelApplication ), true );
				PopUpManager.centerPopUp( browser );
				
				browser.deleteButton.addEventListener( MouseEvent.CLICK, onDeleteButtonClick );
				browser.propertiesButton.addEventListener( MouseEvent.CLICK, onSettingsButtonClick );
				browser.usersList.addEventListener( IndexChangeEvent.CHANGE, onUserChanged );
				
				for ( var i : int = 0; i < browser.usersList.dataProvider.length; i ++ )
				{
					if ( browser.usersList.dataProvider.getItemAt( i ).uid == selectedUser.uid )
					{
						browser.usersList.selectedIndex = i;
						browser.usersList.scrollToIndex( i );
						break;
					}
				}
				
				browse();
			}
		}
		
		private function hideProjectsDialog() : void
		{
			if ( browser )
			{
				browser.deleteButton.removeEventListener( MouseEvent.CLICK, onDeleteButtonClick );
				browser.propertiesButton.removeEventListener( MouseEvent.CLICK, onSettingsButtonClick );
				
				browser.removeEventListener( CloseEvent.CLOSE, onCloseBrowser );
				PopUpManager.removePopUp( browser );
				browser = null;
				
				destroy();
				
				dispatchEvent( new CloseEvent( CloseEvent.CLOSE ) );
			}
		}
		
		private function onUserChanged( e : IndexChangeEvent ) : void
		{
		  lastUser = selectedUser = browser.usersList.selectedItem;
		  browse();
		}
		
		private function onDeleteButtonClick( e : MouseEvent ) : void
		{
			Alert.showConfirmation( 'Действительно удалить "' + browser.selectedProject.name + '"?', deleteConfirmationClick );
		}
		
		private function deleteConfirmationClick( e : CloseEvent ) : void
		{
			if ( e.detail == Alert.YES )
			{
				remove( browser.selectedProject.id );
			}
		}
		
		private function onSettingsButtonClick( e : MouseEvent ) : void
		{
			showProjectSettingsDialog();
		}
		
		private function onCloseBrowser( e : CloseEvent ) : void
		{
			if ( e.detail == Alert.OK )
			{
			  selectedProject = browser.selectedProject;
			}
			
			hideProjectsDialog();
		}
		
		private var dialog : EditProjectSettingsDialog; 
		
		private function showProjectSettingsDialog() : void
		{
			if ( ! dialog )
			{
				var info : ProjectInfo = browser.selectedProject.clone();
				
				dialog = new EditProjectSettingsDialog();
				dialog.defaultGenre = info.genre;
				dialog.info = info;
				dialog.addEventListener( CloseEvent.CLOSE, onCloseProgectSettingsDialog );
				
				PopUpManager.addPopUp( dialog, DisplayObject( FlexGlobals.topLevelApplication ), true );
				PopUpManager.centerPopUp( dialog );
			}
		}
		
		private function onCloseProgectSettingsDialog( e : CloseEvent ) : void
		{
		  HintManager.hideAll();
			
		  if ( e.detail == Alert.OK )
		   {
				update( dialog.info );
		   }
		  else if ( e.detail == Alert.CANCEL )
		  {
			  hideProjectSettingsDialog();  
		  }
		}
		
		private function hideProjectSettingsDialog() : void
		{
			if ( dialog )
			{
				dialog.removeEventListener( CloseEvent.CLOSE, onCloseProgectSettingsDialog );
				PopUpManager.removePopUp( dialog );
				dialog = null;
			}
		}
		
		override protected function next() : void
		{
			switch( currentTask )
			{
				case TASK_BROWSE_PROJECTS :
					switch( _status )
					{
						case SimpleTask.NONE : browser.loading = true;
							                   browser.loadingText.text = 'Секундочку...';
							                   _browse();
							                   break;
						case BROWSING: _status = SimpleTask.NONE;
							           browser.loading = false;
							           break;
					}
					break;
				
				case TASK_REMOVE_PROJECT :
					switch( _status )
					{
						case SimpleTask.NONE : browser.loading = true;
							                   browser.loadingText.text = 'Удаляю...';
							                   _remove();
							                   break;
						case REMOVING : _browse();
							            break;
						case BROWSING : _status = SimpleTask.NONE;
							            browser.loading = false;
							            break;
					}
					break;
				
				case TASK_UPDATE_INFO :
					switch( _status )
					{
						case SimpleTask.NONE : dialog.applying = true; 
							                   _update();
							                   break;
						case UPDATING_INFO : hideProjectSettingsDialog();
											 browser.loading = true;
											 browser.loadingText.text = 'Секундочку...';
							                 _browse();
							                 break;
						case BROWSING : _status = SimpleTask.NONE;
							               browser.loading = false;
										 
							            break;
						case UPDATE_INFO_ERROR : _status = SimpleTask.NONE;
							                     dialog.applying = false;
												 break;
					}
				break;	
			}
			
			super.next();
		}
		
		private function onBrowseProjects( e : BrowseProjectEvent ) : void
		{
			api.removeListener( BrowseProjectEvent.BROWSE_PROJECTS, onBrowseProjects );
			
			//Удаляем из списка уже открытый проект
			var projects : Array = new Array();
			
			if ( e.projects )
			{
				for each( var project : Object in e.projects )
				{
					if ( ( ! info ) || ( project.id != info.id ) )
					{
						projects.push( project );
					}
				}	
			}
			
			if ( browser )
			{
				browser.updateProjects( projects, currentTask != BROWSING );
				
				if ( selectedUser.uid == VKApi.userInfo.uid )
				{
					browser.tools.visible = browser.tools.includeInLayout = true;
					browser.header.text = 'Мои миксы';
					browser.projectsList.height = 300;
				}
				else
				{
					browser.tools.visible = browser.tools.includeInLayout = false;
					browser.header.text = 'Миксы ' + VKApi.formatUserFullName( selectedUser );
					browser.projectsList.height = 338;
				}
				
			}
			
			next();
		}
		
		private function _browse() : void
		{
			_status = BROWSING;
			api.addListener( BrowseProjectEvent.BROWSE_PROJECTS, onBrowseProjects, this );
			api.browseProjectsByNetUserID( selectedUser.uid );
		}
		
		private function browse() : void
		{
			currentTask = TASK_BROWSE_PROJECTS;
			next();
		}
		
		private function onRemoved( e : RemoveProjectEvent ) : void
		{
			api.removeListener( RemoveProjectEvent.REMOVE, onRemoved );
			next();
		}
		
		private function _remove() : void
		{
			_status = REMOVING;
			api.addListener( RemoveProjectEvent.REMOVE, onRemoved, this );
			api.removeProject( cRemovingProjectID );
		}
		
		private var cRemovingProjectID : int;
		
		private function remove( projectID : int ) : void
		{
			cRemovingProjectID = projectID;
			currentTask = TASK_REMOVE_PROJECT;
			next();
		}
		
		private function checkError( errorCode : int ) : void
		{
			if ( dialog )
			{
				if ( errorCode == APIError.PROJECT_WITH_THIS_NAME_ALREADY_EXISTS )
				{
					dialog.applying = false;
					dialog.setError( 'У тебя уже есть микс с таким именем. Придумай другое имя.' );
					_status = UPDATE_INFO_ERROR;
				}
				else
				if ( errorCode != APIError.OK )
				{
					HintManager.show( 'Ошибка обновления микса...', true, dialog.icon );
					_status = UPDATE_INFO_ERROR;
				}
			}
		}
		
		private function onUpdated( e : SaveProjectEvent ) : void
		{
			checkError( e.errorCode );
			api.removeListener( SaveProjectEvent.UPDATE, onUpdated );
			next();
		}
		
		private function _update() : void
		{
			_status = UPDATING_INFO;
			api.addListener( SaveProjectEvent.UPDATE, onUpdated, this );
			api.updateProject( cUpdatingProjectInfo, null );
		}
		
		private var cUpdatingProjectInfo : Object;
		
		private function update( info : Object ) : void
		{
			cUpdatingProjectInfo = ObjectUtil.clone( info );
			
			if ( cUpdatingProjectInfo.created )
			{
				delete cUpdatingProjectInfo.created;
			}
			
			if ( cUpdatingProjectInfo.updated )
			{
				delete cUpdatingProjectInfo.updated;
			}
			
			currentTask = TASK_UPDATE_INFO;
			next();
		}
	}
}