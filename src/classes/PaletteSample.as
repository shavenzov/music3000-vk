/**
 * Представляет собой аудио образец в палитре секвенсора
 */
package classes
{	
	import com.audioengine.core.IAudioData;
	import com.audioengine.sources.IAudioDataSource;
	
	public class PaletteSample
	{
        //Сам образец
		private var _source : IAudioData;
		//Загрузчик образца
		private var _loader : IAudioDataSource;
		
		private var _sd : BaseDescription;
        
		/**
		 * Указывает, что во время загрузки образца произошла ошибка 
		 */		
		public var error : Boolean; 
        		
		public function PaletteSample( sd : BaseDescription, source : IAudioData = null )
		{
		  super();
		  
		  _sd = sd;
		  _source = source;
		}
		
		public function get description() : BaseDescription
		{
			return _sd;
		}
		
		public function get loader() : IAudioDataSource
		{
			return _loader;
		}
		
		public function setLoader( loader : IAudioDataSource ) : void
		{
			_loader = loader;
		}
		
		/**
		 *Определяет можно ли работать с этим семплом. 
		 *( Т.е. он может быть ещё не до конца загружен и соответственно работать с ним в этот момент нельзя )  
		 */
		public function get ready() : Boolean
		{
			return _source != null;
		}
		
		/**
		 * 
		 * Аудио источник данных
		 * 
		 */		
		public function get source() : IAudioData
		{
			return _source;
		}	
		
		/**
		 * Устанавливает источник данных
		 *  
		 */
		public function setSource( source : IAudioData ) : void
		{
			_source = source;
		}
	}
}