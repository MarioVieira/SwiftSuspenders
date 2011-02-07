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
	import org.swiftsuspenders.support.injectees.OneRequiredOneOptionalPropertyMethodInjectee;
	import org.swiftsuspenders.support.injectees.OptionalOneRequiredParameterMethodInjectee;
	import org.swiftsuspenders.support.injectees.TwoParametersMethodInjectee;
	import org.swiftsuspenders.support.nodes.InjectionNodes;
	import org.swiftsuspenders.support.types.Clazz;
	import org.swiftsuspenders.support.types.Interface;

	public class MethodInjectionPointTest
	{
		protected var injector:Injector;

		[Before]
		public function runBeforeEachTest():void
		{
			injector = new Injector();
		}

		[After]
		public function teardown():void
		{
			Injector.purgeInjectionPointsCache();
			injector = null;
		}
		[Test]
		public function injectionOfTwoUnnamedPropertiesIntoMethod():void
		{
			var injectee:TwoParametersMethodInjectee = new TwoParametersMethodInjectee();
			var node:XML = XML(InjectionNodes.METHOD_SET_DEPENDENCIES_INJECTION_NODE_TWO_PARAMETER.metadata);
			injector.mapSingleton(Clazz);
			injector.mapSingletonOf(Interface, Clazz);
			var injectionPoint:MethodInjectionPoint = new MethodInjectionPoint(node);

			injectionPoint.applyInjection(injectee, injector);

			Assert.assertTrue("dependency 1 should be Clazz instance", injectee.getDependency() is Clazz);		
			Assert.assertTrue("dependency 2 should be Interface", injectee.getDependency2() is Interface);	
		}
		[Test]
		public function injectionOfOneRequiredOneOptionalPropertyIntoMethod():void
		{
			var injectee:OneRequiredOneOptionalPropertyMethodInjectee = new OneRequiredOneOptionalPropertyMethodInjectee();
			var node:XML = XML(InjectionNodes.METHOD_SET_DEPENDENCIES_INJECTION_NODE_ONE_REQUIRED_ONE_OPTIONAL_PARAMETER.metadata);
			injector.mapSingleton(Clazz);
			var injectionPoint:MethodInjectionPoint = new MethodInjectionPoint(node);

			injectionPoint.applyInjection(injectee, injector);
			
			Assert.assertTrue("dependency 1 should be Clazz instance", injectee.getDependency() is Clazz);		
			Assert.assertTrue("dependency 2 should be null", injectee.getDependency2() == null);	
		}

		[Test(expects="org.swiftsuspenders.InjectorError")]
		public function gatheringParametersForMethodsWithUnTypedParamertsThrowException() : void
		{
			var node:XML = XML(InjectionNodes.METHOD_NODE_WITH_UNTYPED_PARAMETER.metadata);
			var injectionPoint:MethodInjectionPoint = new MethodInjectionPoint(node);
		}

		[Test]
		public function injectionAttemptWithUnmappedOptionalMethodInjectionDoesntThrow():void
		{
			var injectee:OptionalOneRequiredParameterMethodInjectee = new OptionalOneRequiredParameterMethodInjectee();
			var node:XML = XML(InjectionNodes.OPTIONAL_METHOD_INJECTION_NODE_WITH_REQUIRED_PARAMETER.metadata);
			var injectionPoint:MethodInjectionPoint = new MethodInjectionPoint(node);

			injectionPoint.applyInjection(injectee, injector);

			Assert.assertNull("dependency must be null", injectee.getDependency());
		}
	}
}