/*
 * Copyright (c) 2009-2011 the original author or authors
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */

package  org.swiftsuspenders.injectionpoints
{
	import org.flexunit.Assert;
	import org.swiftsuspenders.Injector;
	import org.swiftsuspenders.support.injectees.ClassInjectee;

	public class PostConstructInjectionPointTests
	{
		[After]
		public function teardown():void
		{
			Injector.purgeInjectionPointsCache();
		}
		
		[Test]
		public function invokeXMLConfiguredPostConstructMethod():void
		{
			var injectee:ClassInjectee = applyPostConstructToClassInjectee();
			
			Assert.assertTrue(injectee.someProperty);
		}
		
		private function applyPostConstructToClassInjectee():ClassInjectee
		{
			var injectee:ClassInjectee = new ClassInjectee();
			var injector:Injector = new Injector(
				<types>
					<type name='org.swiftsuspenders.support.injectees::ClassInjectee'>
						<postconstruct name='doSomeStuff' order='1'/>
					</type>
				</types>);
			injector.injectInto(injectee);
			
			return injectee;
		}
	}
}