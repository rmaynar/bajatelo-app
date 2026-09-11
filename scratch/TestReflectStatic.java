import java.lang.reflect.Field;
class A {
    private static String foo = "old";
}
public class TestReflectStatic {
    public static void main(String[] args) throws Exception {
        A a = new A();
        Field f = A.class.getDeclaredField("foo");
        f.setAccessible(true);
        f.set(a, "new");
        System.out.println("Success");
    }
}
