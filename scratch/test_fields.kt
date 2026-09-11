import com.yausername.youtubedl_android.YoutubeDL
import java.io.File
fun main() {
    val clazz = YoutubeDL::class.java
    for (f in clazz.declaredFields) {
        println(f.name)
    }
}
