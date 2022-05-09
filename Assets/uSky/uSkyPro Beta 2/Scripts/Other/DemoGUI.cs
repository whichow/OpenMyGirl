using UnityEngine;
using UnityEngine.UI;
using System.Collections;
using System.Text;

namespace usky
{
	[AddComponentMenu("uSkyPro/Other/Demo GUI")]
	public class DemoGUI : MonoBehaviour {

		public Text AltitudeText;
		public Transform PlayerCamera = null;
		public Image controlInfo;

		IEnumerator Start()
		{
			if (controlInfo != null) 
			{
				float t = 0;

				// Time to display the image on screen
				yield return new WaitForSeconds (10);

				while (t < 1) 
				{
					controlInfo.color = Color.Lerp (controlInfo.color, new Color (1, 1, 1, 0), t);
					t += Time.deltaTime;
					yield return new WaitForSeconds (0.01f);
				}
				controlInfo.enabled = false;

			} else
				yield return null;
		}
			
		void Update ()
		{
			if (!AltitudeText)
				return;

			if (PlayerCamera) {
				float value = PlayerCamera.transform.position.y;

				StringBuilder strAltitude = new StringBuilder ();
				strAltitude.Append ("Altitude");
				strAltitude.Append ("\n");
				strAltitude.Append (value.ToString ("####"));
				strAltitude.Append (" M");
				AltitudeText.text = strAltitude.ToString ();
			} else {
				AltitudeText.text = string.Empty;
			}
		}
	}
}