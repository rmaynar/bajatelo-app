import java.lang.reflect.Field;
import com.yausername.youtubedl_android.YoutubeDL;

public class TestReflection {
    public static void main(String[] args) {
        try {
            Field f = YoutubeDL.class.getDeclaredField("ffmpegPath");
            System.out.println("Field found: " + f);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
