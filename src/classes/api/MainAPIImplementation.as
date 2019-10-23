package classes.api
{
	import com.serialization.Serialize;
	
	import flash.events.Event;
	
	import mx.core.mx_internal;
	
	import classes.api.data.ProjectInfo;
	import classes.api.data.UserInfo;
	import classes.api.errors.APIError;
	import classes.api.events.AMFErrorEvent;
	import classes.api.events.AMFErrorLayer;
	import classes.api.events.BrowseProjectEvent;
	import classes.api.events.FavoriteEvent;
	import classes.api.events.GetProjectEvent;
	import classes.api.events.GetProjectInfoEvent;
	import classes.api.events.GetUserInfoEvent;
	import classes.api.events.InviteFriendsEvent;
	import classes.api.events.LimitationsEvent;
	import classes.api.events.OrderUserListEvent;
	import classes.api.events.ProTariffsEvent;
	import classes.api.events.ProjectNameEvent;
	import classes.api.events.RemoveProjectEvent;
	import classes.api.events.SaveProjectEvent;
	import classes.api.events.SwitchedOnProModeEvent;
	
	import handler.NetErrorHandler;
	
	use namespace mx_internal;
	
	public class MainAPIImplementation extends SynchroAPI
	{
		/**
		 * Результат последней операции browse Examples 
		 */		
		private var _examples : Array;
		
		public function MainAPIImplementation()
		{
			super();
			processErrorFunction = NetErrorHandler.processError;
			
			Settings.notifier.addListener( Event.CHANGE, onSettingsChanged, this );
			
			if ( Settings.loaded )
			{
				onSettingsChanged( null );
			}
		}
		
		/**
		 * Если настройки были изменены 
		 * @param e
		 * 
		 */		
		private function onSettingsChanged( e : Event ) : void
		{
			nc.connect( Settings.AMF_HOST );
		}
		
		public function get examples() : Array
		{
			return _examples;
		}
		/*
		public function get numProjects() : int
		{
			return _userInfo.numProjects;
		}
		
		public function get maxProjects() : int
		{
			return _userInfo.pro ? int.MAX_VALUE : _userInfo.maxProjects;
		}
		*/
		public function get userInfo() : UserInfo
		{
			return _userInfo;
		}
		
		private function parseProjects( responds : Object, eventType : String, updateExamples : Boolean = false, updateProjects : Boolean = false ) : void
		{
			var data     : Array = responds.data as Array;
			var projects : Array = new Array( data.length );
			
				for ( var i : int = 0; i < data.length; i ++ )
				{
					projects[ i ] = parseProject( data[ i ] );
				}
			
			if ( updateExamples )
			{
			  _examples = projects;	
			}
			
			dispatchEvent( new BrowseProjectEvent( eventType, projects ) );
		}
		
		private function parseProject( data : Object ) : ProjectInfo
		{
			var project : ProjectInfo = new ProjectInfo();
			    project.name = data.name;
			    project.updated = Serialize.timeStampToDate( data.updated );
			    project.created = Serialize.timeStampToDate( data.created );
			    project.userGenre = Serialize.toBoolean( data.userGenre );
			    project.genre = data.genre;
			    project.id = parseInt( data.id );
			    project.owner = parseInt( data.owner );
			    project.tempo = parseInt( data.tempo );
			    project.duration = parseInt( data.duration );
			    project.description = data.description;
			    project.access = data.access;
			    project.readonly = Serialize.toBoolean( data.readonly );
				
			return project;	
		}
		
		private function onBrowseProjects( responds : Object, call : Call ) : void
		{
		   parseProjects( responds, BrowseProjectEvent.BROWSE_PROJECTS, false, true ); 	
		}
		
		public function browseProjects( offset : int = -1, limit : int = -1 ) : void
		{
			call( 'API.browseProjects', onBrowseProjects, offset, limit );
		}
		
		public function browseProjectsByNetUserID( netUserID : String, offset : int = -1, limit : int = -1 ) : void
		{
			call( 'API.browseProjectsByNetUserID', onBrowseProjects, netUserID, offset, limit );
		}
		
		private function onBrowseExamples( responds : Object, call : Call ) : void
		{
			parseProjects( responds, BrowseProjectEvent.BROWSE_EXAMPLES, true );	
		}
		
		public function browseExamples( offset : int = -1, limit : int = -1 ) : void
		{
			call( 'API.browseExamples', onBrowseExamples, offset, limit );
		}
		
		private function onProjectRemoved( responds : Object, call : Call ) : void
		{
			//_userInfo.numProjects --;
			dispatchEvent( new RemoveProjectEvent( RemoveProjectEvent.REMOVE ) );
		}
		
		public function removeProject( projectID : int ) : void
		{
			call( 'API.removeProject', onProjectRemoved, projectID );
		}
		
		private function onSaveProject( responds : Object, call : Call ) : void
		{
			if ( responds != null )
			{	
				dispatchEvent( new SaveProjectEvent( SaveProjectEvent.SAVE, int( responds ) ) );
				return;
			}
			
			dispatchEvent( new AMFErrorEvent( AMFErrorEvent.ERROR, 'При попытке сохранить микс произошла ошибка.', 1000, call, AMFErrorLayer.COMMAND ) );
		}
		
		private function onUpdateProject( responds : Object, call : Call ) : void
		{
			if ( responds != null )
			{
				dispatchEvent( new SaveProjectEvent( SaveProjectEvent.UPDATE, int( responds ) ) );
				return;
			}
			
			dispatchEvent( new AMFErrorEvent( AMFErrorEvent.ERROR, 'При попытке обновить микс произошла ошибка.', 1000, call, AMFErrorLayer.COMMAND ) );
		}
		
		public function saveProject( info : Object, data : String ) : void
		{
			call( 'API.saveProject', onSaveProject, info, data );
		}
		
		public function updateProject( info : Object, data : String ) : void
		{
			call( 'API.updateProject', onUpdateProject, info, data );
		}
		
		private function onGetProject( responds : Object, call : Call ) : void
		{
			if ( ! responds )
			{
				dispatchEvent( new AMFErrorEvent( AMFErrorEvent.ERROR, 'При вызове getProject произошла ошибка.', 1000, call, AMFErrorLayer.COMMAND ) );
			}
			
			var error : int = APIError.OK;
			var data  : String;
			
			if ( responds is Number )
			{
				error = int( responds );
			}
			else
			{
				data = String( responds );
			}
			
			dispatchEvent( new GetProjectEvent( GetProjectEvent.GET_PROJECT, data, error ) );
		}
		
		public function getProject( projectID : int, source : int = ProjectSource.PROJECTS ) : void
		{
			call( 'API.getProject', onGetProject, projectID, source );
		}
		
		private function sendNameEvent( responds : Object, eventType : String ) : void
		{
			var error : Boolean = false;
			var name  : String;
			
			if ( responds is Number )
			{
				error = true;
			}
			else
			{
				name = String( responds );
			}
			
			dispatchEvent( new ProjectNameEvent( eventType, error ? null : name, error ? int( responds ) : APIError.OK ) );
		}
		
		private function onGetDefaultProjectName( responds : Object, call : Call ) : void
		{
			sendNameEvent( responds, ProjectNameEvent.DEFAULT_PROJECT_NAME );
		}
		
		private function onNameResolved( responds : Object, call : Call ) : void
		{
			sendNameEvent( responds, ProjectNameEvent.RESOLVE_NAME );
		}
		
		public function getDefaultProjectName() : void
		{
			call( 'API.getDefaultProjectName', onGetDefaultProjectName );
		}
		
		private function onGotProjectInfo( responds : Object, call : Call ) : void
		{
			if ( ! responds )
			{
				dispatchEvent( new AMFErrorEvent( AMFErrorEvent.ERROR, 'При вызове getProjectInfo произошла ошибка.', 1000, call, AMFErrorLayer.COMMAND ) );
			}
			
			var error : int = APIError.OK;
			var info  : ProjectInfo;
			
			if ( responds is Number )
			{
				error = int( responds );
			}
			else
			{
				info = parseProject( responds );
			}
			
			dispatchEvent( new GetProjectInfoEvent( GetProjectInfoEvent.GET_PROJECT_INFO, info, error ) );
		}
		
		/**
		 * Возвращает информацию о проекте по его id 
		 * @param id
		 * 
		 */		
		public function getProjectInfo( id : String ) : void
		{
			call( 'API.getProjectInfo', onGotProjectInfo, id );
		}
		
		public function resolveName( projectName : String ) : void
		{
			call( 'API.resolveName', onNameResolved, projectName ); 
		}
		
		private function onGotUserInfo( responds : Object, call : Call ) : void
		{
			if ( ! responds )
			{
				dispatchEvent( new AMFErrorEvent( AMFErrorEvent.ERROR, 'При вызове getUserInfo произошла ошибка.', 1000, call, AMFErrorLayer.COMMAND ) );
			}
			
			var error : int = APIError.OK;
			var info  : UserInfo;
			
			if ( responds is Number )
			{
				error = int( responds );
			}
			else
			{
				info = parseUserInfo( responds );
			}
			
			dispatchEvent( new GetUserInfoEvent( GetUserInfoEvent.GET_USER_INFO, info, error ) );	
		}
		
		/**
		 * Получение информации о любом пользователе по его id 
		 * @param id
		 * 
		 */		
		public function getUserInfo( id : int ) : void
		{
			call( 'API.getUserInfo', onGotUserInfo, id );
		}
		
		private function onGotLimitations( responds : Object, call : Call ) : void
		{
			if ( responds != null )
			{
				if ( responds.projects != undefined )
				{
					dispatchEvent( new LimitationsEvent( LimitationsEvent.GOT_LIMITATIONS, responds.projects ) );
					return;
				}
			}
			
			dispatchEvent( new AMFErrorEvent( AMFErrorEvent.ERROR, 'При вызове GOT_LIMITATIONS произошла ошибка.', 1000, call, AMFErrorLayer.COMMAND ) );
		}
		
		public function getLimitations() : void
		{
			call( 'API.getLimitations', onGotLimitations );
		}
		
		public function onSwitchedOnProMode( responds : Object, call : Call ) : void
		{
			if ( responds != null )
			{
				dispatchEvent( new SwitchedOnProModeEvent( SwitchedOnProModeEvent.SWITCHED_ON, int( responds ) ) );
				return;
			}
			
			dispatchEvent( new AMFErrorEvent( AMFErrorEvent.ERROR, 'При вызове switchOnProMode произошла ошибка.', 1000, call, AMFErrorLayer.COMMAND ) );
		}
		
		public function switchOnProMode( priceIndex : int ) : void
		{
			call( 'API.switchOnProMode', onSwitchedOnProMode, priceIndex );
		}
		
		private function onGotProTariffs( responds : Object, call : Call ) : void
		{
			if ( responds != null )
			{
				dispatchEvent( new ProTariffsEvent( ProTariffsEvent.PRO_TARIFFS, responds.tariffs, Serialize.timeStampToDate( responds.time ) ) );
				return;
			}
			
			dispatchEvent( new AMFErrorEvent( AMFErrorEvent.ERROR, 'При вызове getProTariffs произошла ошибка.', 1000, call, AMFErrorLayer.COMMAND ) );
		}
		
		public function getProTariffs() : void
		{
			call( 'API.getProTariffs', onGotProTariffs );
		}
		
		private function onFriendsInvited( responds : Object, call : Call ) : void
		{
			if ( responds != null )
			{
				dispatchEvent( new InviteFriendsEvent( InviteFriendsEvent.INVITE_FRIENDS, int( responds ) ) );
				return;
			}
			
			dispatchEvent( new AMFErrorEvent( AMFErrorEvent.ERROR, 'При вызове inviteFriends произошла ошибка.', 1000, call, AMFErrorLayer.COMMAND ) );
		}
		
		public function inviteFriends( uids : Array ) : void
		{
			call( 'API.inviteFriends', onFriendsInvited, uids );
		}
		
		private function onDoUserInvitedAction( responds : Object, call : Call ) : void
		{
			if ( responds != null )
			{
				dispatchEvent( new InviteFriendsEvent( InviteFriendsEvent.DO_USER_INVITED, int( responds ) ) );
				return;
			}
			
			dispatchEvent( new AMFErrorEvent( AMFErrorEvent.ERROR, 'При вызове doUserInvitedAction произошла ошибка.', 1000, call, AMFErrorLayer.COMMAND ) );
		}
		
		public function doUserInvitedAction( uid : String, inviter_id : int ) : void
		{
			trace( '--',uid, inviter_id, '--' );
			call( 'API.doUserInvitedAction', onDoUserInvitedAction, uid, inviter_id );
		}
		
		private function onOrderedUserList( responds : Object, call : Call ) : void
		{
			if ( responds != null )
			{
				dispatchEvent( new OrderUserListEvent( OrderUserListEvent.ORDER_USER_LIST, responds as Array ) );
				return;
			}
			
			dispatchEvent( new AMFErrorEvent( AMFErrorEvent.ERROR, 'При вызове orderUserList произошла ошибка.', 1000, call, AMFErrorLayer.COMMAND ) );
		}
		
		public function orderUserList( net_user_ids : Array ) : void
		{
			call( 'API.orderUserList', onOrderedUserList, net_user_ids );
		}
		
		private function onAddedToFavorite( responds : Object, call : Call ) : void
		{
			if ( responds != null )
			{
				dispatchEvent( new FavoriteEvent( FavoriteEvent.ADD, int( responds ), call.params[ 1 ], call.params[ 2 ] ) );
				return;
			}
			
			dispatchEvent( new AMFErrorEvent( AMFErrorEvent.ERROR, 'При вызове addToFavorite произошла ошибка.', 1000, call, AMFErrorLayer.COMMAND ) );
		}
		
		public function addToFavorite( source : String, hash : String ) : void
		{
			call( 'API.addToFavorite', onAddedToFavorite, source, hash );
		}
		
		private function onRemovedFromFavorite( responds : Object, call : Call ) : void
		{
			if ( responds != null )
			{
				dispatchEvent( new FavoriteEvent( FavoriteEvent.REMOVE, int( responds ), call.params[ 1 ], call.params[ 2 ] ) );
				return;
			}
			
			dispatchEvent( new AMFErrorEvent( AMFErrorEvent.ERROR, 'При вызове removeFromFavorite произошла ошибка.', 1000, call, AMFErrorLayer.COMMAND ) );
		}
		
		public function removeFromFavorite( source : String, hash : String ) : void
		{
			call( 'API.removeFromFavorite', onRemovedFromFavorite, source, hash );
		}
	}
}