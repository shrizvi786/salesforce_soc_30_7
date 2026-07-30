@isTest
public class HelloTest {
    @isTest
    public static void testGreet() {
        // Call the greet method from the Hello class
        String greeting = Hello.greet();
        
        // Verify that the greeting is not null
        System.assertNotEquals(null, greeting);
        
        // Verify that the greeting is equal to the expected value
        System.assertEquals('Hello, World!', greeting);
    }
        @isTest
    public static void testGreet1() {
        // Call the greet method from the Hello class
        String greeting = Hello.greet();
        
        // Verify that the greeting is not null
        System.assertNotEquals(null, greeting);
        
        // Verify that the greeting is equal to the expected value
        System.assertEquals('Hello, World!', greeting);
    }
}