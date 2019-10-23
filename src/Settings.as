/**
 * Глобальные параметры 
 */
package 
{
	import com.audioengine.core.TimeConversion;
	
	import flash.external.ExternalInterface;
	
	import classes.api.CustomEventDispatcher;

	public class Settings
	{
		public static const PROJECT_ID_PARAM_NAME : String = 'pi';
		public static const LOCAL_CONNECTION_NAME : String = '_Musical_Designer_';
		
		public static const MIN_APPLICATION_WIDTH  : Number = 760;
		public static const MIN_APPLICATION_HEIGHT : Number = 740;
		
		public static const DEFAULT_PROJECT_NAME      : String = 'Torama project';
		public static const DEFAULT_PROJECT_FILE      : String = 'torama_project';
		public static const EXTENSION_FOR_PROJECT     : String = '.xml';
		public static const DEFAULT_PROJECT_FILE_NAME : String = DEFAULT_PROJECT_NAME + EXTENSION_FOR_PROJECT;
		
		public static const SETTINGS_FILE : String = 'data.xml';
		
		/**
		 * Высота линейки по умолчанию 
		 */		
		public static const RULLER_HEIGHT : Number = 18.0;
		
		/**
		 * Высота дорожки по умолчанию 
		 */		
		public static const TRACK_HEIGHT : Number = 60;
		
		/**
		 * BPM проекта по умолчанию 
		 */		
		public static const DEFAULT_PROJECT_BPM : Number = 128.0;
		
		/**
		 * Максимальная громкость звучания дорожки 
		 */		
		public static const MAX_TRACK_SOUND_VOLUME : Number = 2.0;
		/**
		 * Громкость звучания дорожки по умолчанию 
		 */		
		public static const DEFAULT_TRACK_SOUND_VOLUME : Number = 1.6; 
		
		/**
		 * Минимальное BPM 
		 */		
		public static const MIN_BMP : Number = 30;
		
		/**
		 * Максимальное BPM 
		 */		
		public static const MAX_BPM : Number = 350;
		
		/**
		 * Длина timeline проекта по умолчанию в секундах 
		 */		
		public static const DEFAULT_PROJECT_DURATION : Number = 300.0; //5 минут
		
		public static function get DEFAULT_PROJECT_DURATION_IN_FRAMES() : Number
		{
			return TimeConversion.secondsToNumSamples( DEFAULT_PROJECT_DURATION );
		}
		
		/**
		 * Максимальная доступная длина timeline в секундах 
		 */		
		public static const MAX_PROJECT_DURATION : Number = 3600; //1 час
		
		public static function get MAX_PROJECT_DURATION_IN_FRAMES() : Number
		{
			return TimeConversion.secondsToNumSamples( MAX_PROJECT_DURATION );
		}
		
		/**
		 * Адрес amf сервера LOOPERMAN_API 
		 */		
		public static var AMF_HOST : String = 'music3000/';
		
		public static var LOOPERMAN_CATEGORIES : Array = [];
		public static var LOOPERMAN_GENRES    : Array = [];
		
		public static var VK_ALBUM_NAME : String = 'Мои миксы';
		public static var APPLICATION_NAME : String = 'Музыкальный Конструктор';
		public static var APPLICATION_SUPPORT : String = 'vk.com/musdesigner';
		public static var APPLICATION_URL : String = 'vk.com/musconstructor';
		
		public static var VIDEO_HELP : String;
		
		/**
		 * Уведомляет о изменении настроек 
		 */		
		public static const notifier : CustomEventDispatcher = new CustomEventDispatcher();
		
		/**
		 * Настройки загружены или нет 
		 */
		public static var loaded : Boolean;
		
		/**
		 * Используемый протокол. http или https 
		 */		
		public static var protocol : String;
		
		/**
		 * Подставляет в начало url текущий протокол 
		 * @param url
		 * @return 
		 * 
		 */		
		public static function resolveProtocol( url : String ) : String
		{
			if ( ! protocol )
			{
				if ( ExternalInterface.available )
				{
					protocol = ExternalInterface.call( "document.location.protocol.toString" );
				}
				
				if ( ( protocol != 'http:' ) && ( protocol != 'https:' ) )
				{
					protocol = 'http:';
				}
					
				protocol += '//';
			}
			
			return protocol + url;
		}
		
		public static function parseSettings( xml : XML ) : void
		{
			if ( xml.help != undefined )
			{
				if ( xml.help.video != undefined )
				{
					VIDEO_HELP = resolveProtocol( xml.help.video.text() );
				}
			}
			
			if ( xml.vk != undefined )
			{
				if ( xml.vk.albumName != undefined )
				{
					VK_ALBUM_NAME = xml.vk.albumName.text();
				}
				
				if ( xml.vk.support != undefined )
				{
					APPLICATION_SUPPORT = resolveProtocol( xml.vk.support.text() );
				}
			}
			
			AMF_HOST = resolveProtocol( xml.looperman.amfHost );
			
			var item : XML;
			
			for each( item in xml.looperman.localization.categorys.elements( 'item' ) )
			{
				LOOPERMAN_CATEGORIES.push( { id : item.@id.toString(), icon : 'icons/' + item.@icon.toString(), short : ( ( item.@short == undefined ) ? item.text() : item.@short.toString() ), label : item.text() } );
			}
			
			LOOPERMAN_CATEGORIES.sortOn( 'label' );
			
			for each( item in xml.looperman.localization.genres.elements( 'item' ) )
			{
				LOOPERMAN_GENRES.push( { id : item.@id.toString(), label : item.text() } );
			}
			
			LOOPERMAN_GENRES.sortOn( 'label' );
		}
		
		public static function getAcapellaGenderDescription( gender : String ) : String
		{
			if ( gender == 'M' )
				return 'Мужской вокал';
			
			if ( gender == 'F' )
			  return 'Женский вокал';
			
			return gender;
		}
		
		public static function getAcapellaStyleDescription( style : String ) : String
		{
			if ( style == 'R' )
			 return 'Реп';
			
			if ( style == 'S' )
				return 'Песня';
			
			if ( style == 'R&P' )
				return 'Реп и песня';
			
			return style;
		}
		
		public static function getYesNoDescription( value : String ) : String
		{
			if ( value == 'Y' )
				return 'Да';
			
			if ( value == 'N' )
				return 'Нет';
			
			return value;
		}
		
		public static function getCategoryDescription( category : String ) : Object
		{
			var i : int = 0;
			
			while( i < LOOPERMAN_CATEGORIES.length )
			{
				if ( LOOPERMAN_CATEGORIES[ i ].id == category )
				{
					return LOOPERMAN_CATEGORIES[ i ];
				}
				
				i ++;
			}
			
			return { id : category, label : category };
		}
		
		public static function getGenreDescription( genre : String ) : Object
		{
			var i : int = 0;
			
			while( i < LOOPERMAN_GENRES.length )
			{
				if ( LOOPERMAN_GENRES[ i ].id == genre )
				{
					return LOOPERMAN_GENRES[ i ];
				}
				
				i ++;
			}
			
			return { id : genre, label : genre };
		}
		
		public static function processGenres( items : Array, ignoreNotExists : Boolean = false ) : Array
		{
			var result : Array = [];
			var i : int = 0;
			var j : int;
			var genreFound : Boolean
			
			while( i < items.length )
			{
				j = 0;
				genreFound = false;
				
				while( j < LOOPERMAN_GENRES.length )
				{
					if ( items[ i ] == LOOPERMAN_GENRES[ j ].id )
					{
						result.push( LOOPERMAN_GENRES[ j ] );
						genreFound = true;
						break;
					}	
					
					j ++;
				}
				
				if ( ! ignoreNotExists && ! genreFound )
				{
					result.push( { id : items[ i ], label : items[ i ] } );
				}
				
				i ++;
			}
			
			result.sortOn( 'label' );
			return result;
			//return LOOPERMAN_GENRES;
		}
		
		public static function processCategories( items : Array ) : Array
		{
			var result : Array = [];
			var i : int = 0;
			var j : int;
			var categoryFound : Boolean;
			
			while( i < items.length )
			{
				j = 0;
				categoryFound = false;
				
				while( j < LOOPERMAN_CATEGORIES.length )
				{
					if ( items[ i ] == LOOPERMAN_CATEGORIES[ j ].id )
					{
						result.push( LOOPERMAN_CATEGORIES[ j ] );
						categoryFound = true;
						break;
					}	
					
					j ++;
				}
				
				if ( ! categoryFound )
				{
					result.push( { id : items[ i ], label : items[ i ] } );
				}
				
				i ++;
			}
			
			result.sortOn( 'label' );
			return result;
			//return LOOPERMAN_CATEGORYS;
		}
			
	}
}