package com.audioengine.calculations
{
	import com.audioengine.core.AudioData;
	
	import flash.display.Shader;
	import flash.display.ShaderJob;
	import flash.utils.ByteArray;
	
	import pbjAS.PBJ;
	import pbjAS.PBJChannel;
	import pbjAS.PBJParam;
	import pbjAS.PBJType;
	import pbjAS.params.Parameter;
	import pbjAS.regs.RFloat;

	public class Calculation implements ICalculation
	{
		/**
		 * Максимальная ширина 
		 */		
		public static const MAX_DATA_WIDTH : int = 8190;
		
		/**
		 * Максимальная высота 
		 */		
		public static const MAX_DATA_HEIGHT : int = 2048;
		
		/**
		 * Максимальный размер данных для обработки 
		 */		
		public static const MAX_DATA_LENGTH : int = ( MAX_DATA_WIDTH + 1 ) * MAX_DATA_HEIGHT;
		
		/**
		 * Скомпилированный шейдер, готовый для работы 
		 */		
		protected var _shader     : Shader;
		
		/**
		 * Перечисление каналов с которыми будут производиться манипуляции 
		 */		
		protected const _channels : Array = [ PBJChannel.R, PBJChannel.G ];
		
		/**
		 * Длина обрабатываемых данных 
		 */		
		protected var _length : int;
		
		/**
		 * "Высота" обрабатываемых данных 
		 */		
		protected var _height : int;
		private var _heightConstant : Boolean;
		
		/**
		 * Указывает, что необходимо перекомпилировать Shader, перед работой 
		 */		
		protected var _needRebuild : Boolean = true;
		
		/**
		 * Указывает, что изменились св-ва Shader 
		 */		
		protected var _propertyChanged : Boolean = true;
		
		public function Calculation( length : int = 0, height : int = -1 )
		{
		  _length = length;
		  
		  if ( height == -1 )
		  {
			  _height = getOptimizedHeight( length );
		  } 
		  else
		  {
			  _height = height;
			  _heightConstant = true;
		  }	  
		}
		
		public function get length() : int
		{
			return _length;
		}
		
		public function set length( value : int ) : void
		{
			if ( _length != value )
			{
			    _length = value;
				
				if ( ! _heightConstant )
				{
					_height = getOptimizedHeight( _length );
				}	
				
				_propertyChanged = true;	
			}	
		}
		
		public function get bytesLength() : int
		{
			return AudioData.framesToBytes( _length );
		}
		
		public function set bytesLength( value : int ) : void
		{
			length = AudioData.bytesToFrames( value );
		}	
		
		protected function getOptimizedHeight( length : Number ) : Number
		{
		  var cH : Number = 1.0;
		  var i  : Number = 9;	
		  
		  while( i >= 2 )
		  {
			  if ( ( length % i ) == 0 )
			  {
				  cH = i;
				  break
			  }
			  
			  i --;
		  }
			
		  return cH;	
		}	
		
		/**
		 * Инициализирует PixelBender task 
		 * @return инициализрованный PixelBenderTask
		 * 
		 */		
		protected function createPBJ( name : String = 'audioProcessingTask' ) : PBJ
		{	
			var pbj : PBJ = new PBJ();
			    pbj.version = 1;
				pbj.name = name;
				
				pbj.parameters = [
					               new PBJParam( '_OutCoord', new Parameter( PBJType.TFloat2, false, new RFloat( 0, _channels) ) )
					             ];
		   		
				return pbj;	
		}
		
		/**
		 * Добавляет выходной параметр к PixelBender Task 
		 * @param pbj инициализрованный PixelBenderTask
		 * @param reg регистр в памяти
		 * 
		 */		
		protected function addOutput( pbj : PBJ, reg : int ) : void
		{
			pbj.parameters.push( new PBJParam( 'output', new Parameter( PBJType.TFloat2, true, new RFloat( reg, _channels ) ) ) );
		}
		
		/**
		 * Собирает PixelBender task 
		 * 
		 */		
		protected function buildShader() : void
		{
			_needRebuild = false;
		}
		
		/**
		 * Устанавливает новые св-ва для Shader 
		 * 
		 */		
		protected function propertyChanged() : void
		{
			_propertyChanged = false;
		}
		
		/**
		 * Устанавливает входные данные
		 * @param name имя входных данных
		 * @param input сами данные
		 * 
		 */		
		protected function setData( name : String, input : ByteArray ) : void
		{
			_shader.data[ name ][ 'width' ]  = _length / _height;
			_shader.data[ name ][ 'height' ] = _height;
			_shader.data[ name ][ 'input' ]  = input;
		}
		
		/**
		 * Устанавливает значение параметра с указанным именем 
		 * @param name имя параметра
		 * @param value значение параметра
		 * 
		 */		
		protected function setValue( name : String, value : Object ) : void
		{
			_shader.data[ name ][ 'value' ] = value;
		}	
		
		/**
		 * Обрабатывает данные 
		 * @param data поток байтов в который будет записан результат работы
		 * 
		 */		
		public function calculate( data : ByteArray ) : void
		{
			if ( _needRebuild )
			{
				buildShader();
				propertyChanged();
			}
			else if ( _propertyChanged )
			{
				propertyChanged();
			}
			
			var job : ShaderJob = new ShaderJob( _shader, data, _length / _height,  _height );
			
			try
			{
				job.start( true );
			}
			catch( error : ArgumentError )
			{	
				throw new ArgumentError( error.message + ' ( length = ' + _length + ' )' );
			}
		}
		
		public function invalidateBuild() : void
		{
			_needRebuild = true;
		}	
	}
}