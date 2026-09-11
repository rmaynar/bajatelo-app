import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
public class TestSymlink {
    public static void main(String[] args) throws Exception {
        Path target = Paths.get("scratch/target.txt");
        Path link = Paths.get("scratch/link.txt");
        Files.write(target, "hello".getBytes());
        Files.createSymbolicLink(link, target);
        
        System.out.println("Exists before delete target: " + link.toFile().exists());
        Files.delete(target);
        System.out.println("Exists after delete target: " + link.toFile().exists());
        
        if (link.toFile().exists()) {
            System.out.println("Deleting link...");
            link.toFile().delete();
        } else {
            System.out.println("Not deleting link because exists() is false.");
        }
        
        try {
            Files.createSymbolicLink(link, Paths.get("scratch/new_target.txt"));
        } catch (Exception e) {
            System.out.println("Exception creating link: " + e.getClass().getName());
        }
    }
}
