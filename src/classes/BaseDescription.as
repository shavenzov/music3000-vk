package classes
{
	import com.serialization.IXMLSerializable;

	public dynamic class BaseDescription implements IXMLSerializable
	{
		private static const DELIMITER : String = '_';
		
		/**
		 * Уникальный идентификатор семпла 
		 */		
		public var id : String; 
		
		/**
		 *Название 
		 */
		public var name : String;
		
		/**
		 * Автор 
		 */		
		public var author : String;
		
		/**
		 * Длительность семпла в фреймах 
		 */		
		public var duration : Number;
		
		/**
		 * Ударов в секунду 
		 */
		public var bpm : Number;
		
		/**
		 * Тональность 
		 */		
		public var key : String;
		
		/**
		 * Музыкальное направление ( Techno, Industrial и т.д. ) 
		 */
		public var genre : String;
		
		/**
		 * Тип ( звуковые эффекты, ритмы и т.д )
		 */
		public var category : String;
		
		/**
		 * Ссылка на семпл оригинального качества
		 */		
		public var hqurl : String;
		
		/**
		 * Ссылка на сэмпл низкого качества 
		 */		
		public var lqurl : String;
		
		/**
		 * Является ли семпл "Петлей" 
		 */		
		public var loop : Boolean;
		
		/**
		 * Определяет находится ли сэмпл в списке избранных 
		 */		
		public var favorite : Boolean;
		
		public function BaseDescription( id : String, hqurl : String, lqurl : String, name : String, author : String, duration : Number, bpm : Number, key : String, genre : String, category : String, loop : Boolean, favorite : Boolean )
		{
			this.id = id;
			this.hqurl = hqurl;
			this.lqurl = lqurl;
			this.name = name;
			this.author = author;
			this.duration = duration;
			this.bpm = bpm;
			this.key = key;
			this.genre = genre;
			this.category = category;
			this.loop = loop;
			this.favorite = favorite;
		}
		
		public function get sourceID() : String
		{
			return extractSampleSource( id ); 
		}
		
		public function get sampleID() : String
		{
			return extractSampleID( id );
		}
		
		/**
		 * Разделяет идентификатор библиотеки и его источник 
		 * @param sid
		 * @return 
		 * 
		 */		
		public static function deserializeSampleID( id : String ) : Object
		{
			var spl : Array = id.split( DELIMITER );
			
			if ( spl.length == 1 )
			{
				return { id : spl[ 1 ], source : Sources.SAMPLE_SOURCE }; 
			}
			
			return { id : spl[ 1 ], source : spl[ 0 ] };
		}
		
		public static function serializeSampleID( id : String, source : String ) : String
		{
			if ( ! source || ( source == '' ) )
			{
				source = Sources.SAMPLE_SOURCE;
			}
			
			return source + DELIMITER + id;
		}
		
		public static function extractSampleSource( id : String ) : String
		{
		  var spl : Array = id.split( DELIMITER );
		  
		  if ( spl.length == 1 )
		  {
			  return Sources.SAMPLE_SOURCE;  
		  }
			  
		  return spl[ 0 ];
		}
		
		public static function extractSampleID( id : String ) : String
		{
			var spl : Array = id.split( DELIMITER );
			
			if ( spl.length == 1 )
			{
				return id;  
			}
			
			return spl[ 1 ]; 
		}
		
		public static function correctSampleID( id : String ) : String
		{
			var spl : Array = id.split( DELIMITER );
			
			if ( spl.length == 1 )
			{
				return Sources.SAMPLE_SOURCE + DELIMITER + id;  
			}
			
			return id;
		}
		
		public function serializeToXML() : String
		{
			var str : String = '<sample id="' + id + '" />';
			
			return str;
		}
	}
}