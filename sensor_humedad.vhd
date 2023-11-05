library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity sensor_humedad is
    port (
        pin_entrada: in std_logic_vector(7 downto 0);
        pin_salida: out std_logic;
        inicio_tiempo: in std_logic;
        clk: in std_logic;
        servo_angulo: out integer range 0 to 180;  -- Ángulo del servo
        servo_pwm: out std_logic  -- Señal de PWM para control del servo
    );
end entity sensor_humedad;

architecture comportamiento of sensor_humedad is

    constant umbral_humedad: integer := 40;
    constant media_rotacion: integer := 90;

    signal datos_sensor: std_logic_vector(39 downto 0);
    signal humedad: std_logic_vector(15 downto 0);
    signal checksuma: std_logic_vector(7 downto 0);
    signal datos_validos: std_logic := '0';

    signal pin_entrada_init: std_logic_vector(7 downto 0) := "00000000";

    signal angulo_descanso: integer;

    signal tiempo_actual: time;
    signal clk_inicio: time := 0;

begin

    proceso_sensor: process (clk)
    begin
        if rising_edge(clk) then

            if inicio_tiempo = '0' then
                datos_sensor <= (others => '0');
            end if;

            datos_sensor <= pin_entrada & datos_sensor(7 downto 0);

            pin_salida <= pin_entrada;

            if pin_entrada = '0' and datos_sensor(39) = '0' then

                humedad <= datos_sensor(38 downto 23);
                checksuma <= datos_sensor(7 downto 0);

                datos_validos <= '1';

            else
                datos_validos <= '0';
            end if;

            if tiempo_actual - clk_inicio > 50 us then
                clk_inicio <= tiempo_actual;
            end if;
        end if;
    end process proceso_sensor;

    pin_entrada <= pin_entrada_init;

    -- **Proceso para el manejo de umbrales y control del servo**
    proceso_control: process (clk)
    begin
        wait until rising_edge(clk);
        if (datos_validos = '1') then

            if (to_integer(unsigned(humedad)) < umbral_humedad) then

                -- **Estado activado**
                angulo_descanso <= to_integer(unsigned(media_rotacion));
                servo_angulo <= angulo_descanso;
                servo_pwm <= '1';  -- Activa el servo

            else

                -- **Estado desactivado**
                if (servo_angulo > 0) then
                    angulo_descanso <= 0;
                    servo_angulo <= angulo_descanso;
                    servo_pwm <= '0';  -- Desactiva el servo
                end if;

            end if;

            if (servo_angulo == 90 and humedad > 80) then
                servo_angulo <= 0;
                servo_pwm <= '0';
            end if;

            if (servo_angulo = 0) then
                servo_pwm <= '0';  -- El servo está en su posición de descanso
            end if;
        end if;
    end process proceso_control;

end architecture comportamiento;
