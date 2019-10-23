package classes
{
	public dynamic class AcapellaDescription extends BaseDescription
	{
		/**
		 * Пол исполнителя Мужчина/Женщина (M/F) 
		 */		
		public var gender : String;
		
		/**
		 * Вокальный стиль исполнения (R/S/R&S) 
		 */		
		public var style : String;
		
		/**
		 * Используется ли модуляция голоса при исполнении 
		 */		
		public var autotune : Boolean;
		
		public function AcapellaDescription( id : String, hqurl : String, lqurl : String, name : String, author : String, duration : Number, bpm : Number, key : String, genre : String, category : String, 
											 loop : Boolean, favorite : Boolean, gender : String, style : String, autotune : Boolean )
		{
			super( id, hqurl, lqurl, name, author, duration, bpm, key, genre, 'Vocal Loops', loop, favorite );
			
			this.gender = gender;
			this.style  = style;
			this.autotune = autotune;
		}
		
		public static function loadFromSource( data : Object ) : AcapellaDescription
		{	
			return new AcapellaDescription( BaseDescription.serializeSampleID( data.hash, Sources.ACAPELLA_SOURCE ), data.hqurl, data.lqurl, data.name, data.author, data.duration, data.tempo, data.mkey, data.genre, data.category, false, data.favorite, data.gender, data.style, data.autotune == 'Y' ); 	
		}
	}
}