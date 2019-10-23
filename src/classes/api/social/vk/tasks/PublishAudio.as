package classes.api.social.vk.tasks
{
	import com.adobe.crypto.AgeCrypt;
	import com.adobe.serialization.json.JSONDecoder;
	import com.audioengine.core.TimeConversion;
	import com.thread.SimpleTask;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.utils.ByteArray;
	
	import classes.api.data.ProjectAccess;
	import classes.api.data.ProjectInfo;
	import classes.api.social.vk.APIConnection;
	import classes.api.social.vk.Permissions;
	import classes.api.social.vk.VKApi;
	import classes.api.social.vk.events.CustomEvent;
	import classes.api.social.vk.net.MultipartData;
	
	public class PublishAudio extends SimpleTask
	{
		private static const GETTING_PERMISION     : int = 10; //5
		private static const GETTING_UPLOAD_SERVER : int = 20; //5
		public static const UPLOADING             : int = 30; //65
		private static const SAVING                : int = 40; //5
		private static const BROWSING_ALBUMS       : int = 50; //5
		private static const CREATING_ALBUM        : int = 60; //5
		private static const MOVE_TO_ALBUM         : int = 70; //5
		private static const ADDING_TO_WALL        : int = 80; //5
		
		/**
		 * Загрузчик данных на сервер 
		 */		
		private var loader : URLLoader;
		
		/**
		 * Данные для сохранения 
		 */		
		private var data : ByteArray;
		
		/**
		 * Информация о миксе 
		 */		
		private var info : ProjectInfo;
		
		/**
		 * Адрес сервера загрузки 
		 */		
		private var serverURL : String;
		/**
		 * Ответ от сервера после загрузки  
		 */		
		private var serverResponse : Object;
		
		/**
		 * Информация о сохраненном аудио 
		 */		
		private var audioInfo : Object;
		
		/**
		 * Список альбомов пользователя 
		 */		
		private var albums : Array;
		
		/**
		 * Идентификатор нужного нам альбома 
		 */		
		public var album_id : String;
		
		/**
		 * VK API 
		 */		
		private var api : APIConnection;
		
		private var _statusString : String;
		
		/**
		 * Минимальная длина загружаемого файла, принимаемого api ВКонтакте 3с.  
		 */		
		public static const MIN_MUSIC_TIME : Number = 3;
		public static const MIN_MUSIC_FRAMES : Number = TimeConversion.secondsToNumSamples( MIN_MUSIC_TIME );
		
			
		public function PublishAudio( data : ByteArray, info : ProjectInfo )
		{
			super();
			this.data = data;
			this.info = info;
			api = VKApi.impl;
		}
		
		public function cancel() : void
		{
		  if ( loader )
		  {
		    loader.close();
			unsetLoaderListeners();
		  }
		  
		  _status = SimpleTask.ERROR;
		}
		
		public function get statusString() : String
		{
			return  _statusString;
		}
		
		override protected function next():void
		{
			switch( _status )
			{
				case SimpleTask.NONE : _status = GETTING_PERMISION;
					                   _statusString = 'Получение прав доступа к аудиозаписям';
					                   getPermission();  
					
					break;
				
				case GETTING_PERMISION : _status = GETTING_UPLOAD_SERVER;
					                    _statusString = 'Поиск сервера загрузки'; 
					                    getUploadServer();
					
					break;
				
				case GETTING_UPLOAD_SERVER : _status = UPLOADING;
					                         _statusString = 'Загрузка на сервер';
											 upload();
					
					break;
				
				case UPLOADING : _status = SAVING;
					             _statusString = 'Сохранение в Мои аудиозаписи';
								 save();
					
					break;
				
				case SAVING : /*_status = BROWSING_ALBUMS;
					          _statusString = 'Получение списка альбомов';  
					          browseAmbums();
					break;
				
				case BROWSING_ALBUMS : _status = CREATING_ALBUM;
					                   _statusString = 'Создание альбома';
									   createAlbum();
					
					break;
				
				case CREATING_ALBUM : _status = MOVE_TO_ALBUM;
					                  _statusString = 'Перемещение микса в альбом';
									  moveToAlbum();
					
					break;
				
				case MOVE_TO_ALBUM  :*/ _status = ADDING_TO_WALL;
					                  _statusString = 'Публикация на стене';
									  addToWall();
					
					break;
				
				case ADDING_TO_WALL : _status = SimpleTask.DONE;
					
					break;
			}
			
			
			super.next();
		}
		
		private function onAPIError( data : Object ) : void
		{
			var code : int = int( data.error_code );
			
			if ( code != 10007 ) //Operation denied by user. (Пользователь отклонил бокс с просьбой разместить запись) 
			{
				_status = SimpleTask.ERROR;
			}
			
			next();
		}
		
		private function onSettingsChanged( e : CustomEvent ) : void
		{
			api.removeAllObjectListeners( this );
			
			if ( VKApi.params.api_settings & Permissions.AUDIOS )
			{
				
			}
			else
			{
				_status = SimpleTask.ERROR;
			}
			
			next();
		}
		
		private function getPermission() : void
		{
			if ( int( VKApi.params.api_settings ) & Permissions.AUDIOS )
			{
				next();
			}
			else
			{
				ApplicationModel.exitFromFullScreen();
				api.addListener( 'onWindowFocus', onSettingsChanged, this );
				api.callMethod( 'showSettingsBox', Permissions.AUDIOS );
			}
		}
		
		private function onGotUploadServer( data : Object ) : void
		{
			serverURL = data.upload_url;
			next();
		}
		
		private function getUploadServer() : void
		{
			api.api( 'audio.getUploadServer', null, onGotUploadServer, onAPIError );
		}
		
		private function setLoaderListeners() : void
		{
			loader.addEventListener( Event.COMPLETE, onLoaderComplete );
			loader.addEventListener( IOErrorEvent.IO_ERROR, onLoaderError );
		}
		
		private function unsetLoaderListeners() : void
		{
			loader.removeEventListener( Event.COMPLETE, onLoaderComplete );
			loader.removeEventListener( IOErrorEvent.IO_ERROR, onLoaderError );
			loader = null;
		}
		
		private function onLoaderComplete( e : Event ) : void
		{
		  serverResponse = new JSONDecoder( loader.data ).getValue(); 
		  unsetLoaderListeners();
		  next();
		}
		
		private function onLoaderError( e : IOErrorEvent ) : void
		{
			unsetLoaderListeners();
			_status = SimpleTask.ERROR;
			next();
		}
		
		private function upload() : void
		{
		   var data : MultipartData = new MultipartData();
			   data.addFile( this.data, 'file', 'file.mp3', 'audio/mpeg' );
		   
			var req : URLRequest = new URLRequest( serverURL );
			    req.requestHeaders.push(new URLRequestHeader("Content-type", "multipart/form-data; boundary=" + MultipartData.BOUNDARY));
			    req.method = URLRequestMethod.POST;
			    req.data = data.data;
			  
			loader = new URLLoader( req );
			setLoaderListeners();
		}
		
		private function onSaved( data : Object ) : void
		{
			audioInfo = data;
			serverResponse = null;
			serverURL = null;
			next();
		}
		
		private function save() : void
		{
			/*
			serverResponse.artist = artist;
			serverResponse.title  = info.name;
			*/
			api.api( 'audio.save', serverResponse, onSaved, onAPIError ); 
		}
		
		private function onBrowsedAlbums( data : Object ) : void
		{
			albums = data as Array;
			next();
		}
		
		private function browseAmbums() : void
		{
		  api.api( 'audio.getAlbums', { count : 100 }, onBrowsedAlbums, onAPIError );
		}
		
		private function onAlbumAdded( data : Object ) : void
		{
			album_id = data.album_id;
			albums = null;
			next();
		}
		
		private function createAlbum() : void
		{
			//Проверяем существует ли уже необходимы альбом
			if ( albums )
			{
				for each( var album : Object in albums )
				{
					if ( ! ( album is Number ) )
					{
						if ( album.title == Settings.VK_ALBUM_NAME )
						{
							album_id = album.album_id;
							albums = null;
							next();
							return;
						}
					}
				}
			}
			
			api.api( 'audio.addAlbum', { title : Settings.VK_ALBUM_NAME }, onAlbumAdded, onAPIError );
		}
		
		private function onMovedToAlbum( data : Object ) : void
		{
			if ( int( data ) != 1 )
			{
				_status = SimpleTask.ERROR;
			}
			
			next();	
		}
		
		private function moveToAlbum() : void
		{
			api.api( 'audio.moveToAlbum', { aids : audioInfo.aid, album_id : album_id }, onMovedToAlbum, onAPIError );
		}
		
		private function onAddedToWall( data : Object ) : void
		{
			next();
		}	
		
		private function addToWall() : void
		{
			ApplicationModel.exitFromFullScreen();	
			
			var url : String = Settings.resolveProtocol( Settings.APPLICATION_URL );
			
			if ( info.access == ProjectAccess.NOBODY )
			{
				api.api( 'wall.post', { message : "Этот Микс создан приложением Музыкальный Конструктор. Хочешь с легкостью создавать классные миксы? Запускай " + url,
					attachments : "photo-49077246_295553387,audio" + audioInfo.owner_id + "_" + audioInfo.aid + "," + url
				}, onAddedToWall, onAPIError );
			}
			else
			{
				url += '#' + Settings.PROJECT_ID_PARAM_NAME + '=' + AgeCrypt.encode( info.id.toString() );
				
				api.api( 'wall.post', { message : "Этот Микс создан приложением Музыкальный Конструктор. Хочешь сделать ремикс? Запускай " + url,
					attachments : "photo-49077246_295553387,audio" + audioInfo.owner_id + "_" + audioInfo.aid + "," + url
				}, onAddedToWall, onAPIError );
			}
		}
	}
}